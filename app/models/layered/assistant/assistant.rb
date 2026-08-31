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
      has_many :assistant_tools, -> { order(:id) }, dependent: :destroy
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
        assistant_tools.map(&:tool_name)
      end

      # Replaces the set, keeping the rows for names that survive so their
      # ids and timestamps do. Assigning the collection rather than marking
      # the leavers for destruction: a mark cannot be lifted, so a name
      # dropped and re-added before the save would keep its mark and be
      # deleted anyway, taking the counter cache below zero with it.
      def tool_names=(names)
        names = Array(names).map(&:to_s).compact_blank.uniq
        existing = assistant_tools.index_by(&:tool_name)

        self.assistant_tools = names.map { |name| existing[name] || AssistantTool.new(tool_name: name) }
      end
    end
  end
end
