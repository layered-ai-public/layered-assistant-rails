require "test_helper"
require "rails/generators/test_case"
require "generators/layered/assistant/migrations_generator"

class MigrationsGeneratorTest < Rails::Generators::TestCase
  tests Layered::Assistant::Generators::MigrationsGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination

  test "copies engine migrations to host app" do
    FileUtils.mkdir_p File.join(destination_root, "db/migrate")

    Dir.chdir(destination_root) { run_generator }

    engine_migrations = Dir[Layered::Assistant::Engine.root.join("db/migrate/*.rb")]
    assert_operator engine_migrations.size, :>, 0, "engine should have migrations"

    host_migrations = Dir[File.join(destination_root, "db/migrate/*.rb")]
    assert_equal engine_migrations.size, host_migrations.size
  end

  test "copied migrations include layered_assistant marker" do
    FileUtils.mkdir_p File.join(destination_root, "db/migrate")

    Dir.chdir(destination_root) { run_generator }

    Dir[File.join(destination_root, "db/migrate/*.rb")].each do |path|
      assert_match(/\.layered_assistant\.rb$/, path)
    end
  end

  test "copied migrations include origin comment" do
    FileUtils.mkdir_p File.join(destination_root, "db/migrate")

    Dir.chdir(destination_root) { run_generator }

    Dir[File.join(destination_root, "db/migrate/*.rb")].each do |path|
      content = File.read(path)
      assert_match(/This migration comes from layered_assistant/, content)
    end
  end

  test "skips migrations that already exist" do
    FileUtils.mkdir_p File.join(destination_root, "db/migrate")

    Dir.chdir(destination_root) do
      run_generator
      count_after_first = Dir[File.join(destination_root, "db/migrate/*.rb")].size

      run_generator
      count_after_second = Dir[File.join(destination_root, "db/migrate/*.rb")].size

      assert_equal count_after_first, count_after_second
    end
  end

  test "assigns sequential timestamps" do
    FileUtils.mkdir_p File.join(destination_root, "db/migrate")

    Dir.chdir(destination_root) { run_generator }

    timestamps = Dir[File.join(destination_root, "db/migrate/*.rb")].sort.map do |path|
      File.basename(path).match(/^(\d+)_/)[1].to_i
    end

    timestamps.each_cons(2) do |a, b|
      assert_equal a + 1, b, "timestamps should be sequential"
    end
  end
end
