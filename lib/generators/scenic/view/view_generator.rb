require "rails/generators"
require "rails/generators/active_record"

module Scenic
  module Generators
    class ViewGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration
      source_root File.expand_path("../templates", __FILE__)

      def split_name_and_arguments
        args = name.split(":")
        self.name = args.shift
        assign_names!(name)

        args.each do |arg|
          setter = "#{arg}="
          if respond_to?(setter)
            send(setter, true)
          end
        end
      end

      def create_view_definition
        create_file definition.path
      end

      def create_migration_file
        if creating_new_view? || destroying_initial_view?
          migration_template(
            "db/migrate/create_view.erb",
            "db/migrate/create_#{plural_file_name}.rb"
          )
        else
          migration_template(
            "db/migrate/update_view.erb",
            "db/migrate/update_#{plural_file_name}_to_version_#{version}.rb"
          )
        end
      end

      def self.next_migration_number(dir)
        ::ActiveRecord::Generators::Base.next_migration_number(dir)
      end

      no_tasks do
        def previous_version
          @previous_version ||=
            Dir.entries(Rails.root.join(*%w(db views)))
              .map { |name| version_regex.match(name).try(:[], "version").to_i }
              .max
        end

        def version
          @version ||= destroying? ? previous_version : previous_version.next
        end

        def migration_class_name
          if creating_new_view?
            super
          else
            "Update#{class_name.pluralize}ToVersion#{version}"
          end
        end
      end

      private

      attr_accessor :materialized

      def version_regex
        /\A#{plural_file_name}_v(?<version>\d+)\.sql\z/
      end

      def creating_new_view?
        previous_version == 0
      end

      def definition
        Scenic::Definition.new(plural_file_name, version)
      end

      def destroying?
        behavior == :revoke
      end

      def destroying_initial_view?
        destroying? && version == 1
      end
    end
  end
end
