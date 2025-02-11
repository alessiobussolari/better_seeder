# lib/better_seeder/utils.rb

module BetterSeeder
  module Utils

    class << self
      # Trasforma un nome di classe in snake_case.
      # Esempio: "Campaigns::Campaign" => "campaigns_campaign"
      def transform_class_name(class_name)
        elements = class_name.split("::").map(&:underscore)
        # Aggiunge "_structure.rb" all'ultimo elemento
        elements[-1] = "#{elements[-1]}_structure.rb"
        elements.join("/")
      end

      def logger(message: nil)
        if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
          Rails.logger.info message
        else
          puts message
        end
      end

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
