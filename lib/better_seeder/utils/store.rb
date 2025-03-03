# Questo file definisce il modulo +BetterSeeder::Utils::Store+ che offre
# metodi per memorizzare e recuperare record generati e per gestire la configurazione globale.
#
module BetterSeeder
  module Utils
    module Store
      class << self

        @generated_records = {}

        ##
        # Restituisce l'hash contenente i record generati.
        #
        # @return [Hash] hash con i record generati per ciascun modello.
        #
        def generated_records
          @generated_records
        end

        ##
        # Memorizza un record generato per il modello specificato.
        #
        # Se non esiste già, viene inizializzato un array vuoto per il modello.
        #
        # @param model_name [String, Symbol] il nome del modello
        # @param record [Object] il record da memorizzare
        #
        def store_generated_record(model_name, record)
          @generated_records[model_name.to_s] ||= []
          @generated_records[model_name.to_s] << record
        end

      end
    end
  end
end