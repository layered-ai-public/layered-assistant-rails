require "test_helper"
require "rails/generators/test_case"
require "generators/layered/assistant/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests Layered::Assistant::Generators::InstallGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination

  # -- JS -----------------------------------------------------------------

  test "adds JS import after layered_ui import" do
    stub_layered_ui_installed

    Dir.chdir(destination_root) { run_generator }

    assert_file "app/javascript/application.js" do |content|
      assert_match 'import "layered_ui"', content
      assert_match 'import "layered_assistant"', content
      assert ui_before_assistant?(content), "layered_ui import should appear before layered_assistant import"
    end
  end

  test "does not duplicate JS import on second run" do
    stub_layered_ui_installed

    Dir.chdir(destination_root) do
      run_generator
      run_generator
    end

    assert_file "app/javascript/application.js" do |content|
      assert_equal 1, content.scan('import "layered_assistant"').count
    end
  end

  test "detects JS import with single quotes" do
    stub_layered_ui_installed(js_content: %(import '@hotwired/turbo-rails'\nimport 'layered_ui'))

    Dir.chdir(destination_root) { run_generator }

    assert_file "app/javascript/application.js" do |content|
      assert_equal 1, content.scan(%r{layered_assistant}).count
    end
  end

  # -- Initialiser --------------------------------------------------------

  test "creates initialiser" do
    stub_layered_ui_installed

    Dir.chdir(destination_root) { run_generator }

    assert_file "config/initializers/layered_assistant.rb" do |content|
      assert_match "Layered::Assistant.authorize", content
    end
  end

  test "does not overwrite existing initialiser" do
    stub_layered_ui_installed
    FileUtils.mkdir_p File.join(destination_root, "config/initializers")
    File.write File.join(destination_root, "config/initializers/layered_assistant.rb"), "# custom\n"

    Dir.chdir(destination_root) { run_generator }

    assert_file "config/initializers/layered_assistant.rb" do |content|
      assert_equal "# custom\n", content
    end
  end

  # -- Routes -------------------------------------------------------------

  test "mounts engine in routes" do
    stub_layered_ui_installed
    FileUtils.mkdir_p File.join(destination_root, "config")
    File.write File.join(destination_root, "config/routes.rb"), <<~RUBY
      Rails.application.routes.draw do
      end
    RUBY

    Dir.chdir(destination_root) { run_generator }

    assert_file "config/routes.rb" do |content|
      assert_match 'mount Layered::Assistant::Engine => "/layered/assistant"', content
    end
  end

  test "does not duplicate engine mount on second run" do
    stub_layered_ui_installed
    FileUtils.mkdir_p File.join(destination_root, "config")
    File.write File.join(destination_root, "config/routes.rb"), <<~RUBY
      Rails.application.routes.draw do
      end
    RUBY

    Dir.chdir(destination_root) do
      run_generator
      run_generator
    end

    assert_file "config/routes.rb" do |content|
      assert_equal 1, content.scan("Layered::Assistant::Engine").count
    end
  end

  private

  def stub_layered_ui_installed(js_content: nil)
    FileUtils.mkdir_p File.join(destination_root, "app/assets/tailwind")
    FileUtils.mkdir_p File.join(destination_root, "app/javascript")
    FileUtils.mkdir_p File.join(destination_root, "db/migrate")

    js = js_content || %(import "@hotwired/turbo-rails"\nimport "layered_ui")

    File.write File.join(destination_root, "app/assets/tailwind/application.css"), %(@import "tailwindcss";\n@import "./layered_ui";)
    File.write File.join(destination_root, "app/javascript/application.js"), js
  end

  def ui_before_assistant?(content)
    ui_pos = content.index(%r{import.*layered_ui})
    assistant_pos = content.index(%r{import.*layered_assistant})
    ui_pos && assistant_pos && ui_pos < assistant_pos
  end
end
