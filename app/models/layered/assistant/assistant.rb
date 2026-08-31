module Layered
  module Assistant
    class Assistant < ApplicationRecord
      include Ownable

      # UID
      has_secure_token :uid

      # Associations
      belongs_to :default_model, class_name: "Layered::Assistant::Model", optional: true, counter_cache: :assistants_count
      belongs_to :persona, optional: true, counter_cache: :assistants_count
      has_many :assistant_skills, dependent: :destroy
      has_many :skills, through: :assistant_skills
      has_many :assistant_tools, dependent: :destroy, autosave: true
      has_many :conversations, dependent: :destroy

      # Validations
      validates :name, presence: true
      validates :default_model, presence: true, if: :public?

      # Scopes
      scope :by_name, -> { order(name: :asc, created_at: :desc) }
      scope :by_created_at, -> { order(created_at: :desc) }
      scope :publicly_available, -> { where(public: true) }

      # The tools this assistant may call, by the name the model calls them.
      # An assistant with none calls nothing: the set is opt-in, so adding a
      # tool to the application does not hand it to every assistant at once.
      def tool_names
        assistant_tools.reject(&:marked_for_destruction?).map(&:tool_name)
      end

      def tool_names=(names)
        names = Array(names).map(&:to_s).compact_blank.uniq

        assistant_tools.each do |assistant_tool|
          assistant_tool.mark_for_destruction unless names.include?(assistant_tool.tool_name)
        end

        (names - assistant_tools.map(&:tool_name)).each do |name|
          assistant_tools.build(tool_name: name)
        end
      end
    end
  end
end
