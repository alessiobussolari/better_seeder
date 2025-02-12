# frozen_string_literal: true

# spec/better_seeder/data_generator_spec.rb
__END__
require "spec_helper"

RSpec.describe BetterSeeder::Generators::DataGenerator do
  before(:all) do
    # Define a dummy structure class for testing.
    class DummyStructure < ::BetterSeeder::Structure::Utils
      def self.structure
        { foo: [:string, -> { "bar" }] }
      end

      def self.seed_config
        { file_name: "dummy_seed", columns: { excluded: [] }, generate_data: true, count: 3, load_data: false }
      end

      def self.unique_keys
        []  # No uniqueness constraints for this dummy structure.
      end
    end

    # Make sure the constant is set so that the generator can find it.
    Object.const_set("DummyStructure", DummyStructure)
  end

  before do
    # Stub file existence and load so that the generator bypasses actual file operations.
    allow(File).to receive(:exist?).and_return(true)
    allow(Kernel).to receive(:load)
  end

  it "generates the specified number of records" do
    records = described_class.generate(model: "Dummy", count: 3)
    expect(records.size).to eq(3)
    records.each do |record|
      expect(record[:foo]).to eq("bar")
    end
  end
end
