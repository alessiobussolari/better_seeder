module BetterSeeder
  module Farms
    class Farmer
      # Genera dati fittizi per il modello specificato utilizzando il file di structure.
      #
      # Opzioni attese (Hash):
      #   :model => Nome del modello come stringa, es. 'Media::Participant'
      #   :count => Numero di record da generare (default: 10)
      #
      # Se la classe di structure definisce il metodo `unique_keys` (che deve restituire un array di array,
      # es. [[:media_id, :creator_id], [:role]]), verrà controllato che ogni record generato sia univoco,
      # sia in memoria (tra quelli generati in questa esecuzione) che rispetto ai dati già presenti nel database.
      # Se il record è duplicato, verrà rigenerato.
      #
      # Se la classe di structure definisce il metodo `seed_schema`, il record verrà validato tramite Dry-schema.
      #
      # @return [Array<Hash>] Array di record validati e univoci generati
      def self.generate(options = {})
        model_name = options[:model] or raise ArgumentError, "Missing :model option"
        count      = options[:count]  || 10

        # Costruisce il percorso del file di structure.
        # Ad esempio, per il modello "Media::Participant", il file atteso sarà:
        # "db/seed/structure/media/participant_structure.rb"
        structure_file = File.expand_path(
          File.join(BetterSeeder.configuration.structure_path, "#{model_name.underscore}_structure.rb"),
          Dir.pwd
        )
        raise "Structure file not found: #{structure_file}" unless File.exist?(structure_file)

        # Carica il file di structure.
        load structure_file

        # Costruisce il nome della classe di structure: semplice concatenazione.
        # Es: "Media::Participant" => "Media::ParticipantStructure"
        structure_class_name = "#{model_name}Structure"
        begin
          structure_class = Object.const_get(structure_class_name)
        rescue error
          message = "Structure class not found: #{structure_class_name}"
          BetterSeeder::Utils.logger(message: message)
          raise error
        end

        generation_rules = structure_class.structure
        raise "Structure must be a Hash" unless generation_rules.is_a?(Hash)

        # Recupera lo schema per la validazione, se definito.
        schema = structure_class.respond_to?(:seed_schema) ? structure_class.seed_schema : nil

        # Gestione dei vincoli di unicità.
        # Se il metodo unique_keys è definito, lo si aspetta come array di array,
        # ad esempio: [[:media_id, :creator_id], [:role]]
        unique_key_sets = structure_class.respond_to?(:unique_keys) ? structure_class.unique_keys : []
        # Pre-carica i valori già presenti nel database per ciascun gruppo di colonne.
        unique_sets = unique_key_sets.map do |cols|
          existing_keys = Set.new
          # Usa pluck per recuperare le colonne specificate dal modello.
          # Se il gruppo è di una sola colonna, pluck restituirà un array di valori; se multi, un array di array.
          db_rows = Object.const_get(model_name).pluck(*cols)
          db_rows.each do |row|
            composite_key = cols.size == 1 ? row.to_s : row.join("_")
            existing_keys.add(composite_key)
          end
          { columns: cols, set: existing_keys }
        end

        generated_records = []
        progressbar = ProgressBar.create(total: count, format: '%a %B %p%% %t')
        attempts = 0

        # Continua a generare record finché non si raggiunge il numero richiesto.
        while generated_records.size < count
          attempts += 1
          record = {}
          generation_rules.each do |attribute, rule|
            # Ogni rule è un array: [tipo, generatore]
            generator = rule[1]
            value = generator.respond_to?(:call) ? generator.call : generator
            record[attribute] = value
          end

          # Se è definito uno schema, valida il record.
          if schema
            result = schema.call(record)
            unless result.success?
              message = "[ERROR] Record validation failed for #{model_name}: #{result.errors.to_h}"
              BetterSeeder::Utils.logger(message: message)
              progressbar.increment
              next  # Rigenera il record se la validazione fallisce.
            end
          end

          # Controlla i vincoli di unicità: verifica che il record non sia già presente
          duplicate = unique_sets.any? do |unique_set|
            composite_key = unique_set[:columns].map { |col| record[col].to_s }.join("_")
            unique_set[:set].include?(composite_key)
          end
          next if duplicate

          # Aggiorna le strutture per il controllo di unicità con il nuovo record.
          unique_sets.each do |unique_set|
            composite_key = unique_set[:columns].map { |col| record[col].to_s }.join("_")
            unique_set[:set].add(composite_key)
          end

          generated_records << record
          progressbar.increment
        end

        message = "[INFO] Generated #{generated_records.size} unique records for #{model_name} after #{attempts} attempts."
        BetterSeeder::Utils.logger(message: message)
        generated_records
      end
    end
  end
end
