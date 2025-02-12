module BetterSeeder
  module Farms
    class Farmer
      class << self
        def generate(options = {})
          model_name = options[:model] or raise ArgumentError, 'Missing :model option'
          count      = options[:count] || 10

          # Costruisce il percorso del file di structure.
          structure_file = File.expand_path(
            File.join(BetterSeeder.configuration.structure_path, "#{model_name.underscore}_structure.rb"),
            Dir.pwd
          )
          raise "Structure file not found: #{structure_file}" unless File.exist?(structure_file)

          # Carica il file di structure.
          load structure_file

          # Costruisce il nome della classe di structure: es. "Media::Participant" => "Media::ParticipantStructure"
          structure_class_name = "#{model_name}Structure"
          begin
            structure_class = Object.const_get(structure_class_name)
          rescue error
            message = "Structure class not found: #{structure_class_name}"
            BetterSeeder::Utils.logger(message: message)
            raise error
          end

          generated_records = []

          while generated_records.size < count
            new_record = nil
            loop do
              new_record = build_record(model_name, structure_class)
              new_record = inject_parent_keys(model_name, new_record, structure_class)
              break if validate_record(new_record, structure_class) &&
                       !record_exists?(model_name, new_record, structure_class, generated_records)
            end
            generated_records.push(new_record)
          end

          generated_records
        end

        private

        def record_exists?(_model_name, record, structure_class, generated_records)
          # Se non è definito il metodo unique_keys, non eseguiamo il controllo
          return false unless structure_class.respond_to?(:unique_keys)

          unique_key_sets = structure_class.unique_keys
          return false if unique_key_sets.empty?

          # Determina il modello associato: si assume che il nome del modello sia
          # dato dalla rimozione della stringa "Structure" dal nome della classe di structure.
          model_class_name = structure_class.to_s.sub(/Structure$/, '')
          model_class      = Object.const_get(model_class_name)

          # Per ogni set di chiavi uniche, costruiamo le condizioni della query
          unique_key_sets.each do |key_set|
            conditions = {}
            key_set.each do |col|
              conditions[col] = record[col]
            end
            # Se esiste un record nel database che soddisfa le condizioni, restituisce true.
            return true if generated_records.find do |record|
              conditions.all? { |key, value| record[key] == value }
            end.present?
            return true if model_class.where(conditions).exists?
          end

          false
        end

        def build_record(_model_name, structure_class)
          generation_rules = structure_class.structure
          raise 'Structure must be a Hash' unless generation_rules.is_a?(Hash)

          record = {}
          generation_rules.each do |attribute, rule|
            # Ogni rule è un array nel formato [tipo, generatore]
            generator         = rule[1]
            value             = generator.respond_to?(:call) ? generator.call : generator
            record[attribute] = value
          end

          record
        end

        def inject_parent_keys(_model_name, record, structure_class)
          config       = structure_class.respond_to?(:seed_config) ? structure_class.seed_config : {}
          parents_spec = config[:parents]
          return record unless parents_spec.present?

          parents_spec.each do |parent_config|
            parent_model = parent_config[:model]
            column       = parent_config[:column]

            # Tenta di ottenere un record del parent dal pool BetterSeeder.generated_records se disponibile.
            # Usiamo il nome del modello come chiave nel pool.
            pool_key      = parent_model.to_s
            parent_record = if defined?(BetterSeeder.generated_records) &&
                               BetterSeeder.generated_records[pool_key] &&
                               !BetterSeeder.generated_records[pool_key].empty?
                              BetterSeeder.generated_records[pool_key].sample
                            else
                              BetterSeeder.generated_records[pool_key] = parent_model.all
                              BetterSeeder.generated_records[pool_key].sample
                            end

            raise "Parent record not found for #{parent_model}" unless parent_record

            # Inietta nel record la chiave esterna indicata nella configurazione.
            # binding.pry if model_name == "Media::Participant"
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
