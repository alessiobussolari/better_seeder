# spec/better_seeder/configuration_spec.rb
require "spec_helper"

RSpec.describe BetterSeeder do
  describe ".configuration" do
    it "returns default configuration values if not overridden" do
      config = BetterSeeder.configuration
      expect(config.log_language).to eq(:en)

      if defined?(Rails) && Rails.respond_to?(:root)
        expect(config.structure_path.to_s).to include("db/seed/structure")
        expect(config.preload_path.to_s).to include("db/seed/preload")
      else
        expect(config.structure_path).to include("db/seed/structure")
        expect(config.preload_path).to include("db/seed/preload")
      end
    end

    it "allows overriding configuration via BetterSeeder.configure" do
      BetterSeeder.configure do |config|
        config.log_language = :it
        config.structure_path = "/tmp/structure"
        config.preload_path = "/tmp/preload"
      end
      config = BetterSeeder.configuration
      expect(config.log_language).to eq(:it)
      expect(config.structure_path).to eq("/tmp/structure")
      expect(config.preload_path).to eq("/tmp/preload")
    end
  end
end
