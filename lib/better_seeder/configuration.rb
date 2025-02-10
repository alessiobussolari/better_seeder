# lib/better_seeder/configuration.rb

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
end
