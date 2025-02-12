# frozen_string_literal: true

# lib/better_seeder/utils.rb
#
# = BetterSeeder::Utils
#
# Questo modulo fornisce metodi di utilità per la gestione dei seed. In particolare,
# consente di trasformare i nomi delle classi in formato snake_case con il suffisso "_structure.rb",
# gestire i messaggi di log e configurare il livello del logger per ActiveRecord.

module BetterSeeder
  module Utils
    class << self
      ##
      # Trasforma un nome di classe in snake_case e aggiunge il suffisso "_structure.rb".
      #
      # ==== Esempio
      #   transform_class_name("Campaigns::Campaign")
      #   # => "campaigns/campaign_structure.rb"
      #
      # ==== Parametri
      # * +class_name+ - Stringa che rappresenta il nome della classe, eventualmente suddiviso in
      #   namespace separati da "::".
      #
      # ==== Ritorno
      # Restituisce una stringa con il nome della classe in formato snake_case e l'ultimo elemento
      # terminato con "_structure.rb".
      #
      def transform_class_name(class_name)
        elements     = class_name.split('::').map(&:underscore)
        # Aggiunge "_structure.rb" all'ultimo elemento
        elements[-1] = "#{elements[-1]}_structure.rb"
        elements.join('/')
      end

      ##
      # Registra un messaggio usando il logger di Rails se disponibile, altrimenti lo stampa su standard output.
      #
      # ==== Parametri
      # * +message+ - Il messaggio da loggare (può essere una stringa o nil).
      #
      # ==== Ritorno
      # Non ritorna un valore significativo.
      #
      def logger(message: nil)
        if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
          Rails.logger.info message
        else
          puts message
        end
      end

      ##
      # Configura il livello del logger per ActiveRecord in base alla configurazione definita in BetterSeeder.
      #
      # ==== Dettagli
      # Il metodo imposta il livello del logger in base al valore di BetterSeeder.configuration.log_level:
      # * +:debug+ -> Logger::DEBUG
      # * +:info+  -> Logger::INFO
      # * +:error+ -> Logger::ERROR
      # Se il livello non corrisponde a nessuna delle opzioni previste, viene impostato il livello +Logger::DEBUG+.
      #
      def log_level_setup
        level = case BetterSeeder.configuration.log_level
                when :debug then Logger::DEBUG
                when :info then Logger::INFO
                when :error then Logger::ERROR
                else Logger::DEBUG
                end

        ActiveRecord::Base.logger.level = level
      end
    end
  end
end
