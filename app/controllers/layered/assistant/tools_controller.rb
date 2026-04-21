module Layered
  module Assistant
    class ToolsController < ApplicationController
      before_action :set_tool, only: [:edit, :update, :destroy]

      def index
        @page_title = "Tools"
        @pagy, @tools = pagy(scoped(Tool).by_name)
      end

      def new
        @page_title = "New tool"
        @tool = Tool.new
      end

      def create
        @tool = Tool.new(tool_params)
        @tool.owner = l_ui_current_user

        if @tool.save
          redirect_to layered_assistant.tools_path, notice: "Tool was successfully created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        @page_title = "Edit tool"
      end

      def update
        if @tool.update(tool_params)
          redirect_to layered_assistant.tools_path, notice: "Tool was successfully updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        if @tool.destroy
          redirect_to layered_assistant.tools_path, notice: "Tool was successfully deleted."
        else
          redirect_to layered_assistant.tools_path, alert: "Tool could not be deleted: #{@tool.errors.full_messages.to_sentence}."
        end
      rescue ActiveRecord::InvalidForeignKey
        redirect_to layered_assistant.tools_path, alert: "Tool could not be deleted because it is assigned to assistants."
      end

      private

      def set_tool
        @tool = scoped(Tool).find(params[:id])
      end

      def tool_params
        params.require(:tool).permit(:name, :description, :input_schema)
      end
    end
  end
end
