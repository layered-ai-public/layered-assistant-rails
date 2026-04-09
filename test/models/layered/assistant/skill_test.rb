require "test_helper"

module Layered
  module Assistant
    class SkillTest < ActiveSupport::TestCase
      test "validates name presence" do
        skill = Skill.new(name: nil)
        assert_not skill.valid?
        assert_includes skill.errors[:name], "can't be blank"
      end

      test "allows optional fields to be blank" do
        skill = Skill.new(name: "Test")
        assert skill.valid?
        assert_nil skill.description
        assert_nil skill.instructions
      end

      test "has many assistants through assistant_skills" do
        skill = layered_assistant_skills(:research)
        assert_includes skill.assistants, layered_assistant_assistants(:general)
      end

      test "prevents deletion when assistant_skills exist" do
        skill = layered_assistant_skills(:research)
        assert_raises(ActiveRecord::RecordNotDestroyed) { skill.destroy! }
      end

      test "allows deletion when no assistant_skills exist" do
        skill = layered_assistant_skills(:empty)
        assert skill.destroy
      end

      test "by_name scope orders alphabetically" do
        skills = Skill.by_name
        assert_equal skills.map(&:name), skills.map(&:name).sort
      end

      test "by_created_at scope orders newest first" do
        skills = Skill.by_created_at
        assert_equal skills.map(&:created_at), skills.map(&:created_at).sort.reverse
      end
    end
  end
end
