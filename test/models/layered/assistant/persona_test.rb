require "test_helper"

module Layered
  module Assistant
    class PersonaTest < ActiveSupport::TestCase
      test "validates name presence" do
        persona = Persona.new(name: nil)
        assert_not persona.valid?
        assert_includes persona.errors[:name], "can't be blank"
      end

      test "validates instructions presence" do
        persona = Persona.new(name: "Test", instructions: nil)
        assert_not persona.valid?
        assert_includes persona.errors[:instructions], "can't be blank"
      end

      test "allows description to be blank" do
        persona = Persona.new(name: "Test", instructions: "Be helpful.")
        assert persona.valid?
        assert_nil persona.description
      end

      test "has many assistants" do
        persona = layered_assistant_personas(:friendly)
        assert_includes persona.assistants, layered_assistant_assistants(:general)
      end

      test "prevents deletion when assistants exist" do
        persona = layered_assistant_personas(:friendly)
        # SQLite FK constraint fires before Rails restrict_with_error in transactional fixtures
        assert_raises(ActiveRecord::InvalidForeignKey) { persona.destroy! }
      end

      test "allows deletion when no assistants exist" do
        persona = layered_assistant_personas(:empty)
        assert persona.destroy
      end

      test "by_name scope orders alphabetically" do
        personas = Persona.by_name
        assert_equal personas.map(&:name), personas.map(&:name).sort
      end

      test "by_created_at scope orders newest first" do
        personas = Persona.by_created_at
        assert_equal personas.map(&:created_at), personas.map(&:created_at).sort.reverse
      end
    end
  end
end
