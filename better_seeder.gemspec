# frozen_string_literal: true

require_relative "lib/better_seeder/version"

Gem::Specification.new do |spec|
  spec.name = "better_seeder"
  spec.version = BetterSeeder::VERSION
  spec.authors = ["alessio_bussolari"]
  spec.email = ["alessio.bussolari@pandev.it"]

  spec.summary       = "BetterSeeder: Simplify and optimize seeding."
  spec.description   = "A Rails gem that provides simple methods to optimize and maintain seed data, making seeding more efficient and your code more maintainable and performant."
  spec.homepage      = "https://github.com/alessiobussolari/better_seeder"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/alessiobussolari/better_seeder"
  #spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  # Specify which files to include in the gem.
  spec.files         = Dir["lib/**/*", "README.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "ffaker", "~> 2.19"             # For generating fake data
  spec.add_dependency "dry-schema", "~> 1.5"          # For defining and validating schemas
  spec.add_dependency "dry-types", "~> 1.5"           # For type definitions used with dry-schema
  spec.add_dependency "ruby-progressbar", "~> 1.11"   # For displaying a progress bar during data generation

  # ActiveSupport and ActiveRecord are assumed to be available in a Rails environment.
  spec.add_runtime_dependency "activesupport", "~> 4.2"
  spec.add_runtime_dependency "activerecord", "~> 4.2"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
