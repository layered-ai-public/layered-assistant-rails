module Layered
  module Assistant
    module AccessHelper
      def l_assistant_accessible?
        block = Layered::Assistant.authorize_block
        return false unless block

        checker = AccessibilityChecker.new(self)
        checker.accessible?(&block)
      end

      class AccessibilityChecker
        def initialize(context)
          @context = context
          @blocked = false
        end

        def accessible?(&block)
          instance_exec(&block)
          !@blocked
        end

        def head(*)
          @blocked = true
        end

        def redirect_to(*)
          @blocked = true
        end

        private

        def method_missing(method, ...)
          @context.send(method, ...)
        end

        def respond_to_missing?(method, include_private = false)
          @context.respond_to?(method, include_private)
        end
      end

      private_constant :AccessibilityChecker
    end
  end
end
