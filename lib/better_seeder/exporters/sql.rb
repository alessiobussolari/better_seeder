module BetterSeeder
  module Exporters
    class Sql < Base
      # Esporta i dati in formato SQL, generando una singola istruzione INSERT
      # che inserisce in blocco tutti i record.
      #
      # Il metodo costruisce una stringa con la sintassi:
      # INSERT INTO table_name (col1, col2, ...) VALUES
      #   (val11, val12, ...),
      #   (val21, val22, ...),
      #   ... ;
      def export
        return if data.empty?
        columns = data.first.keys

        # Crea l'array delle tuple di valori per ciascun record.
        values_list = data.map do |row|
          row_values = columns.map do |col|
            value = row[col]
            # Se il valore è nil restituisce NULL, altrimenti esegue l'escaping delle virgolette singole.
            value.nil? ? "NULL" : "'#{value.to_s.gsub("'", "''")}'"
          end
          "(#{row_values.join(', ')})"
        end

        # Costruisce la query INSERT unica
        insert_statement = "INSERT INTO #{table_name} (#{columns.join(', ')}) VALUES #{values_list.join(', ')};"

        full_path = File.join(full_output_path)

        File.open(full_path, 'w') do |file|
          file.puts(insert_statement)
        end
      end

      def extension
        '.sql'
      end
    end
  end
end
