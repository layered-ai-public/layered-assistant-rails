require "test_helper"

module Layered
  module Assistant
    class PanelHelperTest < ActionView::TestCase
      include PanelHelper
      include Turbo::FramesHelper
      include Engine.routes.url_helpers

      test "panel_header renders a turbo frame" do
        result = layered_assistant_panel_header
        assert_includes result, 'id="assistant_panel_header"'
        assert_includes result, "<turbo-frame"
      end

      test "panel_header forwards HTML attributes" do
        result = layered_assistant_panel_header class: "custom"
        assert_includes result, 'class="custom"'
      end

      test "panel_body renders a turbo frame with src" do
        result = layered_assistant_panel_body
        assert_includes result, 'id="assistant_panel"'
        assert_includes result, "<turbo-frame"
        assert_includes result, "src="
        assert_includes result, "/panel/conversations"
      end

      test "panel_body forwards HTML attributes" do
        result = layered_assistant_panel_body data: { controller: "panel" }
        assert_includes result, 'data-controller="panel"'
      end

      test "public_panel_body renders a turbo frame with assistant src" do
        assistant = layered_assistant_assistants(:coding)
        result = layered_assistant_public_panel_body(assistant: assistant)
        assert_includes result, 'id="assistant_panel"'
        assert_includes result, "<turbo-frame"
        assert_includes result, "src="
        assert_includes result, "/public/panel/conversations"
        assert_includes result, "assistant_id=#{assistant.id}"
      end
    end
  end
end
