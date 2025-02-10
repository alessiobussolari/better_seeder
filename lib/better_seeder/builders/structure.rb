# lib/better_seeder/generators/structure_generator.rb
require 'fileutils'

module BetterSeeder
  module Builders
    class Structure
      TEMPLATE = <<~RUBY
        module %{module_name}
          class %{class_name}Structure < ::BetterSeeder::Structure::Utils
            # Defines generators for each attribute.
            def self.structure
              {
                # Replace with your attribute generators:
                attribute_name: [:string, -> { "your value" }]
              }
            end

            # Optional: Validate generated records using Dry-schema.
            def self.seed_schema
              Dry::Schema.Params do
                # Replace with your validations:
                required(:attribute_name).filled(:string)
              end
            end

            # Specific seeding configuration for %{class_name}.
            def self.seed_config
              {
                file_name: '%{file_name}',
                columns: { excluded: [] },
                generate_data: true,
                count: 10,
                load_data: true,
                parent: nil
              }
            end

            # Optional: Uniqueness constraints.
            def self.unique_keys
              []
            end
          end
        end
      RUBY

      # Generates a structure file for the given model name.
      #
      # @param model_name [String] The full model name (e.g., "MyNamespace::MyModel")
      # @return [String] The full path to the generated file.
      def self.generate(model_name)
        # Split the model name into module parts and the actual class name.
        parts = model_name.split("::")
        class_name = parts.pop
        module_name = parts.empty? ? "Main" : parts.join("::")

        # Determine the file path.
        # For example, for "MyNamespace::MyModel", the file will be placed in:
        # lib/better_seeder/generators/my_namespace/my_model_structure.rb
        folder_path = File.join(BetterSeeder.configuration.structure_path, *parts.map(&:underscore))
        file_name = "#{class_name.underscore}_structure.rb"
        full_path = File.join(folder_path, file_name)

        # Ensure the target directory exists.
        FileUtils.mkdir_p(folder_path) unless Dir.exist?(folder_path)

        # Prepare the file content.
        content = TEMPLATE % {
          module_name: module_name,
          class_name: class_name,
          file_name: "#{class_name.underscore}_seed"
        }

        # Write the template to the file.
        File.write(full_path, content)
        full_path
      end
    end
  end
end
