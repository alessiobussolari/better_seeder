# lib/generators/better_seeder/structure_generator/structure_generator.rb
require 'rails/generators'
require 'better_seeder'

module BetterSeeder
  module Generators
    class StructureGenerator < Rails::Generators::NamedBase
      # No template file is needed as our method generates the file content.
      # Instead, we call the BetterSeeder.generate_structure method.
      def create_structure_file
        say_status("info", "Generating structure file for #{name}", :green)
        # Call the generator method from your gem.
        # It expects a keyword argument :model_name.
        file_path = BetterSeeder.generate_structure(model_name: name)
        say_status("info", "Structure file created at #{file_path}", :green)
      end
    end
  end
end
