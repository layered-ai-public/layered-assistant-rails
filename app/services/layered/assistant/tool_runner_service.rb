module Layered
  module Assistant
    # Runs the tools an assistant message asked for, records a message per
    # result, then queues a fresh assistant message so the model can answer
    # with what the tools returned. That message may ask for tools again,
    # which is the loop max_tool_cycles bounds.
    #
    # A tool that declares `consent :always` is not run here. Its message is
    # recorded with nothing in it, the response stops where it is, and the
    # person talking approves or declines it - at which point #resolve
    # finishes the call and picks the response back up.
    class ToolRunnerService
      DECLINED = "The person you are talking to declined this tool call.".freeze
      STOPPED = "The response was stopped before this tool ran.".freeze

      # Results are reported to the model as JSON, a refusal included, so
      # that being turned down reads like any other unhappy answer.
      def self.error(reason)
        { error: reason }.to_json
      end

      # Writes down a call that was never answered because the response was
      # stopped. Nothing is resumed: stopping means stopping. Returns false if
      # the call is beyond stopping - already answered, or claimed by the job
      # that is running its tool, whose own result is the true one.
      def self.abandon(message)
        message.resolve_tool_call!(status: :declined, content: error(STOPPED), from: %w[pending approved])
      end

      def call(message:)
        return if message.tool_calls.blank?

        conversation = message.conversation
        # The registrations block runs on every registry lookup, by design, so
        # that tool classes reload in development. Resolve the set this
        # conversation may use once for the whole batch rather than per call.
        available = ToolRegistry.for(conversation)
        message.tool_calls.each { |tool_call| record_result(message, tool_call, available) }
        conversation.update_token_totals!

        message.broadcast_response_waiting if conversation.awaiting_consent?

        resume(message)
      end

      # Carries out a call once it has been approved, or writes down the
      # refusal, and resumes the response. The refusal is reported to the
      # model as the tool's result rather than ending the conversation: it
      # can say something useful about being turned down.
      def resolve(message:)
        # An answered call is one this job has already run, or one the response
        # was stopped over. The tool does not run twice - but resuming may be
        # what failed last time, so that is still attempted below.
        if message.content.blank?
          # Held from before the claim, because claiming moves the call to
          # running. Running is the tool being carried out, not an outcome, so
          # the answer is written back under the decision that allowed it.
          decided = message.tool_status

          content = if message.consent_declined?
            error(DECLINED)
          elsif message.claim_tool_call!
            execute(message, message.tool_name, message.tool_arguments, ToolRegistry.for(message.conversation))
          else
            # The claim went elsewhere: the response was stopped before the
            # tool ran, or this job was delivered twice. Either way the tool
            # does not run here, and whoever holds the claim finishes the job.
            return
          end

          return unless message.resolve_tool_call!(status: decided, content: content)

          message.broadcast_updated
          message.conversation.update_token_totals!
        end

        resume(message)
      end

      private

      def record_result(message, tool_call, available)
        name = tool_call.dig("function", "name")
        arguments = tool_call.dig("function", "arguments")
        tool = available.find { |candidate| candidate.tool_name == name }

        # Both protocols name the call they are asking for. Without an id the
        # result cannot be paired back to it, and the provider rejects the next
        # turn - so say so here rather than leaving that trace to explain it.
        if tool_call["id"].blank?
          Rails.logger.error("Tool call for '#{name}' arrived with no id on message #{message.id}")
        end

        if tool&.consent_required?
          record(message, tool_call, name, arguments, content: nil, status: :pending)
        else
          record(message, tool_call, name, arguments, content: execute(message, name, arguments, available))
        end
      end

      def record(message, tool_call, name, arguments, content:, status: nil)
        result = message.conversation.messages.create!(
          role: :tool,
          content: content,
          model_id: message.model_id,
          tool_call_id: tool_call["id"],
          tool_name: name,
          tool_arguments: arguments,
          tool_status: status,
          input_tokens: TokenEstimator.estimate(content),
          tokens_estimated: true
        )
        result.broadcast_created
      end

      # Every failure is reported to the model as the tool's result rather than
      # raised: a bad argument or a missing record is something it can recover
      # from on the next turn.
      def execute(message, name, arguments, available)
        tool = available.find { |candidate| candidate.tool_name == name }
        return error(refusal(name)) unless tool

        result = tool.new(message: message).call(**tool.cast_arguments(parse(arguments)))
        format_result(result)
      rescue Tool::InvalidArguments => e
        error("The tool was called with invalid arguments: #{e.message}")
      rescue => e
        Rails.logger.error("Tool '#{name}' failed: #{e.class}: #{e.message}")
        error("The tool raised an error: #{e.message}")
      end

      # Only reached when a call cannot be run, so the second registry lookup
      # costs nothing on the path that matters. A tool the host never
      # registered and one this assistant was not given are different
      # mistakes, and the model can act on the difference.
      def refusal(name)
        if ToolRegistry.find(name)
          "The tool '#{name}' is not available in this conversation."
        else
          "There is no tool called '#{name}'."
        end
      end

      def parse(arguments)
        return {} if arguments.blank?

        JSON.parse(arguments)
      rescue JSON::ParserError
        raise Tool::InvalidArguments, "the arguments were not valid JSON"
      end

      def format_result(result)
        content = result.is_a?(String) ? result : result.to_json
        content.presence || "The tool returned no output."
      end

      def error(reason)
        self.class.error(reason)
      end

      # One cycle is an assistant message that asked for tools. Counted from
      # the last thing the user said, so each prompt gets a full budget.
      def cycles_since_last_prompt(conversation)
        cutoff = conversation.messages.where(role: :user).maximum(:created_at)
        scope = conversation.messages.where(role: :assistant)
        scope = scope.where(created_at: cutoff..) if cutoff

        scope.where.not(tool_calls: nil).count
      end

      # Picks the response back up once every call in the batch has an answer.
      # Taken under a lock, and refusing to queue a second follow-up, because
      # two calls approved at once would otherwise both find themselves last.
      def resume(message)
        conversation = message.conversation

        conversation.with_lock do
          if conversation.stopped?
            # A tool claimed before the Stop still finishes, and the response
            # is not picked back up. But a tab that loaded while it was
            # running is waiting on it, so say the response is over once
            # nothing is left running - otherwise its composer never comes
            # back.
            message.broadcast_response_complete unless conversation.unresolved_tool_call?
            return
          end

          # Every call in the batch has to hold a result before the model is
          # shown any of them: approving two at once means the first to finish
          # would otherwise send a turn with the second still empty.
          return if conversation.unresolved_tool_call?
          return if awaiting_results?(conversation)
          return if followed_up?(conversation, message)

          if cycles_since_last_prompt(conversation) >= Layered::Assistant.max_tool_cycles
            halt(message)
          else
            continue(message)
          end
        end
      end

      # Results are written down one call at a time, so a batch is briefly
      # part-recorded. A call put to the person talking is answerable the
      # moment its own row exists, and approving it while a slower call in the
      # same batch is still running would otherwise find nothing unresolved -
      # there being no row yet to be unresolved - and send a turn missing that
      # result. So the batch is measured against what the model asked for
      # rather than against what has been written down so far.
      def awaiting_results?(conversation)
        asked = conversation.messages
          .where(role: :assistant).where.not(tool_calls: nil)
          .order(created_at: :desc, id: :desc).first
        return false unless asked

        ids = asked.tool_calls.filter_map { |tool_call| tool_call["id"].presence }
        return false if ids.empty?

        conversation.messages.where(role: :tool, tool_call_id: ids).count < ids.size
      end

      # Whether the conversation has already moved past this batch, which is
      # what makes resuming safe to attempt twice. Any assistant message from
      # this point on is that move, finished or not: a follow-up that has since
      # completed still means the batch was resumed, and a job delivered late
      # must not queue a second response for it. The message passed in is
      # excluded because on the unattended path it is itself an assistant
      # message - the one that asked for the tools.
      def followed_up?(conversation, message)
        conversation.messages
          .where(role: :assistant)
          .where(created_at: message.created_at..)
          .where.not(id: message.id)
          .exists?
      end

      def continue(message)
        follow_up = message.conversation.messages.create!(
          role: :assistant,
          content: nil,
          model_id: message.model_id
        )
        follow_up.broadcast_created
        Messages::ResponseJob.perform_later(follow_up.id)
      end

      def halt(message)
        # The notice is the engine talking, not the model, so it costs nothing.
        # Recording that keeps the conversation out of Conversation#responding?,
        # which would otherwise leave the composer disabled on the next load.
        notice = message.conversation.messages.create!(
          role: :assistant,
          content: "I stopped after #{Layered::Assistant.max_tool_cycles} rounds of tool calls without reaching an answer. Please try rephrasing your request.",
          model_id: message.model_id,
          output_tokens: 0,
          tokens_estimated: true
        )
        notice.broadcast_created
        notice.broadcast_response_complete
        Rails.logger.warn("Tool call limit reached for conversation #{message.conversation_id}")
      end
    end
  end
end
