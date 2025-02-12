module BetterSeeder
  module Exporters
    class Csv < Base
      # Esporta i dati in formato CSV e li salva in un file nella cartella "db/seed/preload".
      # Se la cartella non esiste, viene creata automaticamente.
      def export
        return if data.empty?

        headers = data.first.keys

        # Costruisce il percorso completo del file di output
        full_path = File.join(full_output_path)

        CSV.open(full_path, 'w', write_headers: true, headers: headers) do |csv|
          data.each { |row| csv << row.values }
        end
      end

      def extension
        '.csv'
      end
    end
  end
end
