module Layered
  module Assistant
    module PanelHelper
      # Renders the Turbo Frame tags that connect the layered-ui panel to the
      # assistant engine. Call this inside your layout's +content_for+ blocks:
      #
      #   <% content_for :l_ui_panel_heading do %>
      #     <%= layered_assistant_panel_header %>
      #   <% end %>
      #
      #   <% content_for :l_ui_panel_body do %>
      #     <%= layered_assistant_panel_body %>
      #   <% end %>
      #
      # The header frame is populated by the engine's panel views. The body
      # frame lazy-loads the conversation list from the engine's panel routes.
      #
      # Any extra keyword arguments are forwarded to the respective
      # +turbo_frame_tag+ call as HTML attributes.

      def layered_assistant_panel_header(**options)
        turbo_frame_tag "assistant_panel_header", **options
      end

      def layered_assistant_panel_body(**options)
        turbo_frame_tag "assistant_panel",
          src: layered_assistant.panel_conversations_path,
          **options
      end

      def layered_assistant_public_panel_body(assistant:, **options)
        turbo_frame_tag "assistant_panel",
          src: layered_assistant.public_panel_conversations_path(assistant_id: assistant.id),
          **options
      end
    end
  end
end
