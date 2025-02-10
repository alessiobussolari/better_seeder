module BetterSeeder
  module Exporters
    class Json < Base
      # Esporta i dati in formato JSON e li salva in un file nella cartella "db/seed/preload".
      # Se la cartella non esiste, viene creata automaticamente.
      def export
        # Imposta la directory di output
        full_path = File.join(full_output_path)

        File.open(full_path, 'w') do |file|
          file.write(JSON.pretty_generate(data))
        end
      end

      def extension
        '.json'
      end
    end
  end
end
