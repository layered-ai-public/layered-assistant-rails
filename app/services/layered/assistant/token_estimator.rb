module Layered
  module Assistant
    class TokenEstimator
      def self.estimate(text)
        return nil if text.blank?

        OpenAI.rough_token_count(text)
      end
    end
  end
end
