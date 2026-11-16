module Layered
  module Assistant
    # Whether a provider accepts an API key, asked by the provider form as
    # the key is typed, so a wrong one is flagged before the form is sent.
    class ProviderKeyChecksController < ApplicationController
      # Each check reaches out to the provider, so stop this being used to
      # test keys in bulk. High enough not to trouble someone typing a key.
      rate_limit to: 20, within: 1.minute

      def create
        check = Providers::KeyCheckService.new(protocol: params[:protocol], url: params[:url], secret: params[:secret]).call
        message = check.invalid? ? "This key #{check.message}." : check.message
        render json: { status: check.status, message: message }
      end
    end
  end
end
