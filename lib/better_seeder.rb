require_relative "better_seeder/configuration"
require_relative "better_seeder/structure/utils"
require_relative "better_seeder/generators/data_generator"
require_relative "better_seeder/exporters/base"
require_relative "better_seeder/exporters/json"
require_relative "better_seeder/exporters/csv"
require_relative "better_seeder/exporters/sql"

module BetterSeeder
  class Configuration
    attr_accessor :log_language, :structure_path, :preload_path

    def initialize
      if defined?(Rails) && Rails.respond_to?(:root)
        @log_language   = :en
        @structure_path = Rails.root.join('db', 'seed', 'structure')
        @preload_path   = Rails.root.join('db', 'seed', 'preload')
      else
        @log_language   = :en
        @structure_path = File.join(Dir.pwd, 'db', 'seed', 'structure')
        @preload_path   = File.join(Dir.pwd, 'db', 'seed', 'preload')
      end
    end
  end

  # Restituisce l'istanza globale di configurazione. Se non esiste, viene creata con i valori di default.
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Permette di configurare BetterSeeder tramite un blocco. Ad esempio, in config/initializers/better_seeder.rb:
  #
  #   BetterSeeder.configure do |config|
  #     config.log_language = :en
  #     config.structure_path = Rails.root.join('db', 'seed', 'structure')
  #     config.preload_path = Rails.root.join('db', 'seed', 'preload')
  #   end
  #
  # Se questo blocco viene eseguito, i valori della configurazione verranno aggiornati; altrimenti,
  # verranno utilizzati quelli definiti nel costruttore (default).
  def self.configure
    yield(configuration)
  end

  # Metodo install che crea l'initializer di BetterSeeder in config/initializers
  # con le seguenti impostazioni:
  #   - log_language: lingua da usare per i log (es. :en, :it)
  #   - structure_path: percorso dove sono memorizzati i file di structure (default: Rails.root/db/seed/structure)
  #   - preload_path: percorso dove verranno salvati i file esportati (default: Rails.root/db/seed/preload)
  def self.install
    initializer_path = File.join(Rails.root, "config", "initializers", "better_seeder.rb")

    if File.exist?(initializer_path)
      Rails.logger.info "BetterSeeder initializer already exists at #{initializer_path}"
    else
      content = <<~RUBY
        # BetterSeeder initializer
        # Questo file è stato generato da BetterSeeder.install
        # Configura i parametri di BetterSeeder qui.
        BetterSeeder.configure do |config|
          # Imposta la lingua per i log (es. :en, :it)
          config.log_language = :en

          # Percorso ai file di structure (usato per la generazione dei dati)
          config.structure_path = Rails.root.join('db', 'seed', 'structure')

          # Percorso alla cartella di preload (dove verranno salvati i file esportati)
          config.preload_path = Rails.root.join('db', 'seed', 'preload')
        end
      RUBY

      File.write(initializer_path, content)
      Rails.logger.info "BetterSeeder initializer created at #{initializer_path}"
    end
  end

  # Metodo master della gemma.
  #
  # La configurazione attesa è un hash con la seguente struttura:
  #
  # {
  #   configurations: { export_type: :sql },
  #   data: [
  #     'Campaigns::Campaign',
  #     'Creators::Creator',
  #     'Media::Media',
  #     'Media::Participant'
  #   ]
  # }
  #
  # Per ciascun modello (identificato da stringa), viene:
  #   - Caricato il file di structure relativo, che definisce la configurazione specifica tramite `seed_config`
  #   - Recuperati (o generati) i record, con eventuali controlli di esclusione e iniezione di foreign key per modelli child
  #   - Se abilitato, i record vengono caricati nel database e successivamente esportati nel formato richiesto
  #   - Vengono raccolte statistiche e loggato il tempo totale di esecuzione
  def self.magic(config)
    start_time = Time.now
    stats = {}                   # Statistiche: modello => numero di record caricati
    parent_loaded_records = {}   # Per memorizzare i record creati per i modelli parent

    ActiveRecord::Base.transaction do
      export_type = config[:configurations][:export_type]
      # In questa versione, config[:data] è un array di nomi di modelli (stringhe)
      model_names = config[:data]
      model_names.each do |model_name|
        process_config(model_name, export_type, stats, parent_loaded_records)
      end
    end

    total_time = Time.now - start_time
    log_statistics(stats, total_time)
  end

  private

  # Processa la configurazione per un singolo modello.
  # Carica il file di structure corrispondente e recupera la configurazione tramite `seed_config`.
  # Quindi, esegue il recupero o la generazione dei record, iniezione di eventuali foreign key per modelli child,
  # caricamento nel database (se abilitato) ed esportazione dei dati.
  def self.process_config(model_name, export_type, stats, parent_loaded_records)
    # Costruisce il percorso del file di structure in base al nome del modello.
    # Esempio: per "Campaigns::Campaign", si attende "db/seed/structure/campaigns/campaign_structure.rb"
    structure_file = File.expand_path(
      File.join(BetterSeeder.configuration.structure_path, "#{model_name.underscore}_structure.rb"),
      Dir.pwd
    )
    raise "Structure file not found: #{structure_file}" unless File.exist?(structure_file)

    # Carica il file di structure.
    load structure_file

    # Il nome della classe di structure viene ottenuto semplicemente concatenando "Structure" al nome del modello.
    # Es: "Campaigns::Campaign" => "Campaigns::CampaignStructure"
    structure_class_name = "#{model_name}Structure"
    begin
      structure_class = Object.const_get(structure_class_name)
    rescue NameError
      Rails.logger.error "[ERROR] Structure class not found: #{structure_class_name}"
      return
    end

    # Recupera la configurazione specifica dal file di structure tramite il metodo seed_config.
    # Se non definito, vengono usati dei valori di default.
    seed_config = structure_class.respond_to?(:seed_config) ? structure_class.seed_config : {}
    file_name        = seed_config[:file_name] || "#{model_name.underscore}_seed"
    excluded_columns = seed_config.dig(:columns, :excluded) || []
    generate_data    = seed_config.fetch(:generate_data, true)
    count            = seed_config[:count] || 10
    load_data        = seed_config.fetch(:load_data, true)
    parent           = seed_config[:parent]   # nil oppure valore (o array) per modelli child

    # Log per indicare se il modello è parent o child.
    if parent.nil?
      Rails.logger.info "[INFO] Processing parent model #{model_name}"
    else
      Rails.logger.info "[INFO] Processing child model #{model_name} (parent: #{parent.inspect})"
    end

    # Recupera la classe reale del modello (ActiveRecord).
    model_class = Object.const_get(model_name) rescue nil
    unless model_class
      Rails.logger.error "[ERROR] Model #{model_name} not found."
      return
    end

    # Recupera o genera i record.
    records = if generate_data
                Generators::DataGenerator.generate(model: model_name, count: count)
              else
                model_class.all.map(&:attributes)
              end

    # Rimuove le colonne escluse.
    processed_records = records.map do |record|
      record.reject { |key, _| excluded_columns.include?(key.to_sym) }
    end

    # Se il modello è child, inietta le foreign key.
    if parent
      Array(parent).each do |parent_model_name|
        parent_records = parent_loaded_records[parent_model_name]
        if parent_records.nil? || parent_records.empty?
          Rails.logger.error "[ERROR] No loaded records found for parent model #{parent_model_name}. Cannot assign foreign key for #{model_name}."
        else
          # Il nome della foreign key è ottenuto prendendo l'ultima parte del nome del modello padre,
          # trasformandola in minuscolo e in forma singolare, e aggiungendo "_id".
          foreign_key = parent_model_name.split("::").last.underscore.singularize + "_id"
          processed_records.each do |record|
            record[foreign_key] = parent_records.sample.id
          end
        end
      end
    end

    # Se abilitato, carica i record nel database.
    if load_data
      total_records = processed_records.size
      stats[model_name] = total_records
      created_records = load_records_into_db(model_class, processed_records, total_records, model_name)
      # Se il modello è parent, salva i record creati per poterli utilizzare in seguito per i modelli child.
      parent_loaded_records[model_name] = created_records if parent.nil?
    else
      stats[model_name] = 0
    end

    # Esporta i record nel formato richiesto.
    export_records(model_class, processed_records, export_type, file_name)
  end

  # Carica i record nel database, utilizzando una progress bar per monitorare il progresso.
  # I log delle query SQL vengono temporaneamente disabilitati.
  #
  # @return [Array<Object>] Array dei record creati (istanze ActiveRecord)
  def self.load_records_into_db(model_class, processed_records, total_records, model_name)
    created_records = []
    progressbar = ProgressBar.create(total: total_records, format: '%a %B %p%% %t')
    Rails.logger.info "[INFO] Starting to load #{total_records} records for model #{model_name}..."
    previous_level = ActiveRecord::Base.logger.level
    ActiveRecord::Base.logger.level = Logger::ERROR

    processed_records.each do |record|
      created = model_class.create!(record)
      created_records << created
      progressbar.increment
    end

    ActiveRecord::Base.logger.level = previous_level
    Rails.logger.info "[INFO] Finished loading #{total_records} records into model #{model_name}."
    created_records
  end

  # Esporta i record nel formato specificato (json, csv, sql).
  def self.export_records(model_class, processed_records, export_type, file_name)
    exporter = case export_type.to_s.downcase
               when 'json'
                 Exporters::Json.new(processed_records, output_path: file_name)
               when 'csv'
                 Exporters::Csv.new(processed_records, output_path: file_name)
               when 'sql'
                 table_name = model_class.respond_to?(:table_name) ? model_class.table_name : transform_class_name(model_class.name)
                 Exporters::Sql.new(processed_records, output_path: file_name, table_name: table_name)
               else
                 raise ArgumentError, "Unsupported export type: #{export_type}"
               end

    exporter.export
    Rails.logger.info "[INFO] Exported data for #{model_class.name} to #{file_name}"
  end

  # Log finale con le statistiche raccolte e il tempo totale di esecuzione.
  def self.log_statistics(stats, total_time)
    stats_message = stats.map { |model, count| "#{model}: #{count} records" }.join(", ")
    Rails.logger.info "[INFO] Finished processing all models in #{total_time.round(2)} seconds. Statistics: #{stats_message}"
  end

  # Metodo di utilità per trasformare il nome della classe in un formato in cui le lettere
  # sono in minuscolo e separate da underscore.
  def self.transform_class_name(class_name)
    class_name.split("::").map(&:underscore).join("_")
  end
end
