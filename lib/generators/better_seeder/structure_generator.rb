# frozen_string_literal: true

# lib/generators/better_seeder/structure_generator.rb
require 'rails/generators'

module BetterSeeder
  class StructureGenerator < Rails::Generators::NamedBase
    # Optionally, if you have a template directory, you can set it here:
    # source_root File.expand_path("templates", __dir__)

    def create_structure_file
      say_status('info', "Generating structure file for #{name}", :green)
      file_path = BetterSeeder.generate_structure(model_name: name)
      say_status('info', "Structure file created at #{file_path}", :green)
    end
  end
end
