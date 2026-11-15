module Layered
  module Assistant
    class ProviderResource < Layered::Resource::Base
      model Provider

      columns [
        { attribute: :name, primary: true },
        { attribute: :protocol, render: ->(record, view) { view.t("layered_assistant.protocols.#{record.protocol}") } },
        { attribute: :models_count, label: "Models", link: :provider_models },
        { attribute: :enabled,
          render: ->(record, view) {
            view.tag.span(record.enabled? ? "Enabled" : "Disabled",
                          class: "l-ui-badge l-ui-badge--#{record.enabled? ? 'success' : 'danger'}")
          } }
      ]

      search_fields [ :name, :url ]

      default_sort attribute: :position, direction: :asc

      fields [
        { attribute: :name, data: { provider_template_target: "name" } },
        { attribute: :protocol, as: :select,
          collection: -> { Provider.protocols.keys.map { |k| [ I18n.t("layered_assistant.protocols.#{k}"), k ] } },
          include_blank: "Select:",
          data: { provider_template_target: "protocol", provider_key_check_target: "protocol",
                  action: "provider-key-check#check" } },
        { attribute: :url, as: :url, label: "URL",
          data: { provider_template_target: "url", provider_key_check_target: "url",
                  action: "provider-key-check#check" } },
        # Browsers ignore autocomplete="off" on password fields and fill in
        # the site login; "new-password" stops that, and the data flags ask
        # 1Password, LastPass and Bitwarden to leave the field alone too.
        { attribute: :secret, as: :password, autocomplete: "new-password",
          data: { provider_key_check_target: "secret", action: "provider-key-check#check",
                  "1p_ignore": true, lpignore: true, bwignore: true } },
        { attribute: :enabled, as: :checkbox }
      ]

      # Ownership stays a controller concern: both hooks defer to the
      # engine's own `scoped`/`current_owner!` helpers rather than
      # re-deriving the owner here.
      def self.scope(controller)
        controller.send(:scoped, Provider)
      end

      def self.build_record(controller)
        Provider.new(owner: controller.send(:current_owner!), create_models: "1", check_secret: true)
      end

      def self.find_record(controller, id)
        super.tap { |provider| provider.check_secret = true }
      end
    end
  end
end
