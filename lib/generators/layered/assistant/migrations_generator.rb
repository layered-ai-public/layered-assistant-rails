module Layered
  module Assistant
    module Generators
      class MigrationsGenerator < Rails::Generators::Base
        desc "Copy layered-assistant-rails migrations to the host application"

        def copy_migrations
          engine_migrations_path = Layered::Assistant::Engine.root.join("db/migrate")
          app_migrations_path = Rails.root.join("db/migrate")

          unless engine_migrations_path.exist?
            say "No migrations found in layered-assistant-rails.", :yellow
            return
          end

          existing_migrations = Dir[app_migrations_path.join("*.rb")].map { |f| migration_name(File.basename(f)) }

          timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i

          Dir[engine_migrations_path.join("*.rb")].sort.each do |source|
            basename = File.basename(source)
            name = migration_name(basename)

            if existing_migrations.include?(name)
              say "  skip  #{name} (already exists)", :yellow
              next
            end

            destination = app_migrations_path.join("#{timestamp}_#{name}.layered_assistant.rb")
            content = "# This migration comes from layered_assistant (originally #{basename.split("_").first})\n" + File.read(source)

            create_file destination, content
            timestamp += 1
          end
        end

        private

        # Extract migration name without timestamp prefix
        # e.g. "20260202074215_create_layered_assistant_providers.rb" => "create_layered_assistant_providers"
        def migration_name(filename)
          filename.sub(/^\d+_/, "").sub(/\.layered_assistant\.rb$/, "").sub(/\.rb$/, "")
        end
      end
    end
  end
end
