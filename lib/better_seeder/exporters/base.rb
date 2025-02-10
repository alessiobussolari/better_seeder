# lib/better_seeder/exporter/base_exporter.rb

module BetterSeeder
  module Exporters
    class Base
      # I dati da esportare.
      # output_path: nome del file (senza estensione) da concatenare al preload_path configurato.
      # table_name: (opzionale) nome della tabella, utile ad esempio per SqlExporter.
      attr_reader :data, :output_path, :table_name

      # Inizializza l'exporter.
      #
      # Esempio d'uso:
      #   data = [
      #     { id: 1, name: "Alice", email: "alice@example.com" },
      #     { id: 2, name: "Bob", email: "bob@example.com" }
      #   ]
      #
      #   json_exporter = BetterSeeder::Performers::JsonExporter.new(data, output_path: 'users', table_name: 'users')
      #   json_exporter.export
      #
      # @param data [Array<Hash>] I dati da esportare.
      # @param output_path [String] Nome del file (senza estensione).
      # @param table_name [String] Nome della tabella (usato in SqlExporter).
      def initialize(data, output_path:, table_name: 'my_table')
        @data = data
        # Utilizza il preload_path definito nella configurazione BetterSeeder (impostato nell'initializer).
        @output_path = File.join(BetterSeeder.configuration.preload_path, output_path)
        @table_name = table_name
      end

      # Restituisce la directory in cui salvare i file.
      # In questo caso, utilizza la configurazione BetterSeeder.configuration.preload_path.
      #
      # @return [String] il percorso della directory di output.
      def output_directory
        BetterSeeder.configuration.preload_path.to_s
      end

      # Verifica che la directory di output esista; se non esiste, la crea.
      def ensure_output_directory
        FileUtils.mkdir_p(output_directory) unless Dir.exist?(output_directory)
      end

      # Costruisce il percorso completo del file di output, combinando la directory, l'output_path e l'estensione.
      #
      # @return [String] il percorso completo del file.
      def full_output_path
        ensure_output_directory
        "#{output_path}#{extension}"
      end

      # Metodo astratto per ottenere l'estensione del file (es. ".json", ".csv", ".sql").
      # Le classi derivate devono implementarlo.
      def extension
        raise NotImplementedError, "Subclasses must implement #extension"
      end

      # Metodo astratto per effettuare l'export.
      def export
        raise NotImplementedError, "Subclasses must implement the export method"
      end
    end
  end
end
