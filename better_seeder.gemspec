# frozen_string_literal: true

require_relative "lib/better_seeder/version"

Gem::Specification.new do |spec|
  spec.name          = "better_seeder"
  spec.version       = BetterSeeder::VERSION
  spec.authors       = ["Alessio Bussolari"]
  spec.email         = ["alessio.bussolari@pandev.it"]

  spec.summary       = "Structured, efficient database seeding for Rails applications"
  spec.description   = <<~DESC
    BetterSeeder is a powerful Ruby gem for structured database seeding in Rails applications.
    
    Key features:
    * Structured data generation with dedicated model files
    * Data validation using Dry::Schema
    * Uniqueness constraints across one or multiple columns
    * Parent/child relationship support
    * Multiple export formats (SQL, CSV, JSON)
    * Progress tracking with progress bar
    * Preflight data insertion
    
    Perfect for generating and maintaining consistent seed data in Rails applications.
  DESC

  spec.homepage      = "https://github.com/alessiobussolari/better_seeder"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  # Metadata
  spec.metadata = {
    "allowed_push_host"     => "https://rubygems.org",
    "rubygems_mfa_required" => "true",
    "homepage_uri"          => spec.homepage,
    "source_code_uri"       => spec.homepage,
    "changelog_uri"         => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri"       => "#{spec.homepage}/issues",
    "documentation_uri"     => spec.homepage
  }

  # Include files
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == File.basename(__FILE__)) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.|appveyor|Gemfile)})
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "dry-schema", "~> 1.5"          # Schema validation
  spec.add_dependency "dry-types", "~> 1.5"           # Type definitions for validation
  spec.add_dependency "ffaker", "~> 2.19"             # Realistic data generation
  spec.add_dependency "ruby-progressbar", "~> 1.11"   # Progress tracking
  spec.add_dependency "activerecord", ">= 4.2"        # Database ORM integration
  spec.add_dependency "activesupport", ">= 4.2"       # Rails utility methods

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "yard", "~> 0.9"
end
