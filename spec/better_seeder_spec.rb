# spec/better_seeder_spec.rb
require "spec_helper"
require "pathname"
require "better_seeder"
require "better_seeder/structure/utils"

RSpec.describe BetterSeeder do
  before(:each) do
    # Reset configuration between tests.
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

  describe ".magic" do
    before(:each) do
      # Define a dummy structure for the dummy model.
      class DummyModel < ::BetterSeeder::Structure::Utils
        def self.structure
          { foo: [:string, -> { "bar" }] }
        end

        def self.seed_config
          { file_name: "dummy_model_seed",
            columns: { excluded: [] },
            generate_data: true,
            count: 2,
            load_data: false }
        end

        def self.unique_keys
          []
        end

        def self.seed_schema
          Dry::Schema.Params do
            required(:foo).filled(:string)
          end
        end
      end

      # Define a dummy model constant that BetterSeeder.magic will use.
      stub_const("DummyModel", Class.new)
      # Stub the `where` method on the dummy model so that any call to `.where(...)` returns
      # a double that responds to `exists?` with false, thereby bypassing the ActiveRecord check.
      allow(DummyModel).to receive(:where).and_return(double("Relation", exists?: false))
    end

    before do
      # Stub file existence and load so that the generator bypasses actual file I/O.
      allow(File).to receive(:exist?).and_return(true)
      allow(Kernel).to receive(:load)
      # Stub data generation so that it always returns two records with foo => "bar".
      allow(BetterSeeder::Generators::DataGenerator).to receive(:generate)
                                                          .with(model: "DummyModel", count: 2)
                                                          .and_return([{ foo: "bar" }, { foo: "bar" }])
    end

    it "processes the dummy model without errors" do
      expect {
        BetterSeeder.magic({ configurations: { export_type: :json }, data: ["DummyModel"] })
      }.not_to raise_error
    end

    it "updates statistics for the processed model" do
      logger_double = instance_double("Logger")
      allow(Rails).to receive(:logger).and_return(logger_double)
      expect(logger_double).to receive(:info).with(a_string_matching(/DummyModel: 2 records/))
      BetterSeeder.magic({ configurations: { export_type: :json }, data: ["DummyModel"] })
    end
  end

  describe ".install" do
    it "creates the initializer file if it does not exist" do
      Dir.mktmpdir do |tmpdir|
        rails_root = Pathname.new(tmpdir)
        stub_const("Rails", Module.new do
          define_singleton_method(:root) { rails_root }
        end)
        initializer_path = File.join(rails_root, "config", "initializers", "better_seeder.rb")
        FileUtils.rm_f(initializer_path)
        expect(File).not_to exist(initializer_path)
        BetterSeeder.install
        expect(File).to exist(initializer_path)
      end
    end
  end
end
