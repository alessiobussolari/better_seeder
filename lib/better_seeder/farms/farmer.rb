# frozen_string_literal: true

module BetterSeeder
  module Farms
    class Farmer
      class << self
        def generate(options = {})
          model_name = options[:model] or raise ArgumentError, 'Missing :model option'

          # Costruisce il percorso del file di structure.
          structure_file = File.expand_path(
            File.join(BetterSeeder.configuration.structure_path, "#{model_name.underscore}_structure.rb"),
            Dir.pwd
          )
          raise "Structure file not found: #{structure_file}" unless File.exist?(structure_file)

          load structure_file

          structure_class_name = "#{model_name}Structure"
          begin
            structure_class = Object.const_get(structure_class_name)
          rescue error
            message = "Structure class not found: #{structure_class_name}"
            BetterSeeder::Utils.logger(message: message)
            raise error
          end

          seed_config = structure_class.respond_to?(:seed_config) ? structure_class.seed_config : {}
          total_count = seed_config[:count] || 10

          generated_records = []

          # Se il metodo preflight è definito, usalo per ottenere dati predefiniti
          if structure_class.respond_to?(:preflight)
            preflight_data = structure_class.preflight
            generated_records.concat(preflight_data)
          end

          remaining_count = total_count - generated_records.size

          if seed_config.key?(:childs)
            # Modalità child: per ogni "record padre", generare childs_count record
            childs_count = seed_config.dig(:childs, :count) || 10
            # Calcolo: i record generati saranno i preflight + (remaining_count * childs_count)
            remaining_count.times do |_i|
              childs_count.times do |child_index|
                new_record = nil
                loop do
                  new_record = build_record(model_name, structure_class, child_index, child_mode: true)
                  new_record = inject_parent_keys(model_name, new_record, structure_class)
                  break if validate_record(new_record, structure_class) &&
                    !record_exists?(model_name, new_record, structure_class, generated_records)
                end
                generated_records.push(new_record)
              end
            end
          else
            # Modalità standard: genera remaining_count record
            remaining_count.times do |index|
              new_record = nil
              loop do
                new_record = build_record(model_name, structure_class, index)
                new_record = inject_parent_keys(model_name, new_record, structure_class)
                break if validate_record(new_record, structure_class) &&
                  !record_exists?(model_name, new_record, structure_class, generated_records)
              end
              generated_records.push(new_record)
            end
          end

          generated_records
        end

        # Il metodo build_record ora supporta la modalità child_mode.
        # Se child_mode è true e nella configurazione (seed_config) è definita la chiave childs con :attributes,
        # per ogni attributo viene usato il valore dell'array corrispondente all'indice (child_index) passato.
        def build_record(_model_name, structure_class, index, child_mode: false)
          generation_rules = structure_class.structure
          raise 'Structure must be a Hash' unless generation_rules.is_a?(Hash)

          seed_config = structure_class.respond_to?(:seed_config) ? structure_class.seed_config : {}

          record = {}
          generation_rules.each do |attribute, rule|
            generator = rule[1]
            if child_mode && seed_config.dig(:childs, :attributes, attribute).is_a?(Array)
              values = seed_config[:childs][:attributes][attribute]
              value  = values[index] # index viene passato dal loop interno
            else
              value = generator.respond_to?(:call) ? generator.call : generator
            end
            record[attribute] = value
          end

          record
        end

        # Restituisce il numero di record figli da generare per ciascun "record padre".
        # Nel caso in cui nella configurazione sia presente la chiave childs, restituisce childs[:count],
        # altrimenti default a 10.
        def child_record_count(options = {})
          model_name = options[:model] or raise ArgumentError, 'Missing :model option'

          structure_file = File.expand_path(
            File.join(BetterSeeder.configuration.structure_path, "#{model_name.underscore}_structure.rb"),
            Dir.pwd
          )
          raise "Structure file not found: #{structure_file}" unless File.exist?(structure_file)

          load structure_file
          structure_class_name = "#{model_name}Structure"
          structure_class = Object.const_get(structure_class_name)
          seed_config = structure_class.respond_to?(:seed_config) ? structure_class.seed_config : {}
          seed_config.dig(:childs, :count) || 10
        end

        private

        def record_exists?(_model_name, record, structure_class, generated_records)
          return false unless structure_class.respond_to?(:unique_keys)

          unique_key_sets = structure_class.unique_keys
          return false if unique_key_sets.empty?

          model_class_name = structure_class.to_s.sub(/Structure$/, '')
          model_class      = Object.const_get(model_class_name)

          unique_key_sets.each do |key_set|
            conditions = {}
            key_set.each do |col|
              conditions[col] = record[col]
            end
            return true if generated_records.find { |r| conditions.all? { |key, value| r[key] == value } }
            return true if model_class.where(conditions).exists?
          end

          false
        end

        def inject_parent_keys(_model_name, record, structure_class)
          config       = structure_class.respond_to?(:seed_config) ? structure_class.seed_config : {}
          parents_spec = config[:parents]
          return record if parents_spec.blank?

          parents_spec.each do |parent_config|
            parent_model = parent_config[:model]
            column       = parent_config[:column]
            pool_key     = parent_model.to_s

            unless defined?(BetterSeeder.generated_records) &&
              BetterSeeder.generated_records[pool_key] &&
              !BetterSeeder.generated_records[pool_key].empty?
              BetterSeeder.generated_records[pool_key] = parent_model.all
            end

            parent_record = BetterSeeder.generated_records[pool_key].sample
            raise "Parent record not found for #{parent_model}" unless parent_record

            record[column] = parent_record[:id]
          end

          record
        end

        def validate_record(record, structure_class)
          return true unless structure_class.respond_to?(:seed_schema_validation)

          schema = structure_class.seed_schema_validation
          result = schema.call(record)
          return true if result.success?

          raise result.errors.to_h
        end
      end
    end
  end
end
