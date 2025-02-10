# spec/better_seeder_spec.rb

require "spec_helper"
require "tmpdir"
require "fileutils"
require "pathname"
require "better_seeder"
require "better_seeder/configuration"
require "better_seeder/structure/utils"

RSpec.describe BetterSeeder do
  before(:each) do
    # Reset configuration between tests
    BetterSeeder.instance_variable_set(:@configuration, nil)
  end

  describe ".configuration" do
    it "returns default configuration values" do
      config = BetterSeeder.configuration
      expect(config.log_language).to eq(:en)
      expect(config.structure_path.to_s).to include("db/seed/structure")
      expect(config.preload_path.to_s).to include("db/seed/preload")
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

  describe ".install" do
    it "creates the initializer file if it does not exist" do
      Dir.mktmpdir do |tmpdir|
        fake_root = Pathname.new(tmpdir)
        # Stub Rails.root to return our fake root.
        stub_const("Rails", Module.new do
          define_singleton_method(:root) { fake_root }
        end)
        initializer_path = File.join(fake_root, "config", "initializers", "better_seeder.rb")
        FileUtils.rm_f(initializer_path)
        expect(File).not_to exist(initializer_path)
        BetterSeeder.install
        expect(File).to exist(initializer_path)
        content = File.read(initializer_path)
        expect(content).to include("BetterSeeder.configure do |config|")
      end
    end
  end
end
