require 'dry-types'

module BetterSeeder
  # Superclasse per tutte le structures.
  # Fornisce il modulo Types da utilizzare per la definizione dei tipi.
  module Structure
    class Utils
      module Types
        include Dry.Types()
      end
    end
  end
end

BetterSeederTypes = BetterSeeder::Structure::Utils::Types
