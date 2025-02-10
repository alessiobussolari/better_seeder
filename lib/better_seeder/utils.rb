# lib/better_seeder/utils.rb

module BetterSeeder
  module Utils
    # Trasforma un nome di classe in snake_case.
    # Esempio: "Campaigns::Campaign" => "campaigns_campaign"
    def self.transform_class_name(class_name)
      elements = class_name.split("::").map(&:underscore)
      # Aggiunge "_structure.rb" all'ultimo elemento
      elements[-1] = "#{elements[-1]}_structure.rb"
      elements.join("/")
    end
  end
end
