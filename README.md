# BetterSeeder

**BetterSeeder** is a Rails gem designed to simplify and centralize your application's seeding process. It provides a flexible system to generate dynamic data, validate it using Dry-schema, enforce uniqueness constraints, load it into the database, and export it in various formats (SQL, CSV, JSON). Configuration is centralized via a Rails initializer, while model-specific logic is defined in dedicated structure files.

---

## Features

- **Dynamic Data Generation**  
  Define custom data generators for each model in dedicated structure files.

- **Validation and Uniqueness**  
  Validate generated records using Dry-schema and enforce uniqueness constraints (both single and multi-column).

- **Loading & Exporting**  
  - Load generated data directly into your database (with support for parent/child relationships).  
  - Export data as a single SQL INSERT statement, or in CSV or JSON formats.

- **Centralized Configuration**  
  Easily customize settings such as `log_language`, `structure_path`, and `preload_path` via a Rails initializer. If no initializer is provided, default values are used.

- **Automatic Initializer Installation**  
  Use the `BetterSeeder.install` method to automatically create the initializer file in your Rails app.

---

## Installation

Add the gem to your Gemfile:

```ruby
gem 'better_seeder'
```

Then run:

```bash
bundle install
```

---

## Configuration

BetterSeeder uses a centralized configuration defined in `BetterSeeder.configuration`. You can override the default settings via an initializer. For example, create a file:

```ruby
# config/initializers/better_seeder.rb
require 'better_seeder'

BetterSeeder.configure do |config|
  config.log_language   = :en
  config.structure_path = Rails.root.join('db', 'seed', 'structure')
  config.preload_path   = Rails.root.join('db', 'seed', 'preload')
end
```

If these values are set in the initializer, they will be used; otherwise, the gem will fall back to its default values.

---

## Install Method

BetterSeeder provides an `install` method that automatically creates an initializer file. To run the installer, simply execute in your Rails console:

```ruby
BetterSeeder.install
```

This command creates (if not already present) the file `config/initializers/better_seeder.rb` with content similar to:

```ruby
# BetterSeeder initializer
BetterSeeder.configure do |config|
  config.log_language   = :en
  config.structure_path = Rails.root.join('db', 'seed', 'structure')
  config.preload_path   = Rails.root.join('db', 'seed', 'preload')
end
```

---

## Structure Files

For each model, create a structure file that centralizes the logic for generating, validating, and configuring seed data. Each structure file should define at least the following methods:

- **`structure`**  
  Returns a hash where each key represents an attribute and its value is an array in the format `[type, lambda_generator]`.

- **`seed_schema` (Optional)**  
  Defines a Dry-schema for validating the generated records.

- **`seed_config`**  
  Returns a hash with model-specific seeding settings:
    - `file_name`: The output file name (without extension)
    - `columns: { excluded: [...] }`: Columns to exclude from the generated data
    - `generate_data`: Boolean flag indicating whether to generate data dynamically (if false, existing records are used)
    - `count`: The number of records to generate (default: 10)
    - `load_data`: Boolean flag indicating whether the generated records should be inserted into the database
    - `parent`: For child models, this specifies the parent model(s) used for injecting foreign keys

- **`unique_keys` (Optional)**  
  Returns an array of column groups (each group is an array of symbols) that must be unique.  
  For example:

  ```ruby
  def self.unique_keys
    [[:email], [:first_name, :last_name]]
  end
  ```

### Example Structure File

For a generic model `MyModel` in the namespace `MyNamespace`, create a file at `db/seed/structure/my_namespace/my_model_structure.rb`:

```ruby
# db/seed/structure/my_namespace/my_model_structure.rb
module MyNamespace
  class MyModelStructure < BetterSeeder::StructureBase
    # Defines generators for each attribute.
    def self.structure
      {
        name:       [:string,   -> { FFaker::Name.name }],
        email:      [:string,   -> { FFaker::Internet.email }],
        created_at: [:datetime, -> { Time.zone.now }]
      }
    end

    # Optional: Validate generated records using Dry-schema.
    def self.seed_schema
      Dry::Schema.Params do
        required(:name).filled(:string)
        required(:email).filled(:string)
        required(:created_at).filled(:time)
      end
    end

    # Specific seeding configuration for MyModel.
    def self.seed_config
      {
        file_name: 'my_model_seed',
        columns: { excluded: [:id, :updated_at] },
        generate_data: true,
        count: 50,
        load_data: true,
        parent: nil
      }
    end

    # Optional: Uniqueness constraints; for example, email must be unique.
    def self.unique_keys
      [[:email]]
    end
  end
end
```

---

## How It Works

When you call `BetterSeeder.magic` with a configuration that contains an array of model names (as strings), the gem will:

1. **Load Structure Files**  
   For each model, the gem loads the corresponding structure file from `BetterSeeder.configuration.structure_path`.

2. **Retrieve Seeding Configurations**  
   It calls the model's `seed_config` method to get its specific settings.

3. **Generate or Retrieve Records**  
   Using the `structure` method, the gem generates data dynamically (or retrieves existing records) and validates them with `seed_schema` if provided. Uniqueness is enforced based on `unique_keys`.

4. **Handle Parent/Child Relationships**  
   For child models, foreign keys are automatically injected using the records from the parent models.

5. **Load and Export**  
   If enabled (`load_data: true`), the generated records are inserted into the database and then exported in the specified format (SQL, CSV, or JSON). Export files are saved in the directory defined by `BetterSeeder.configuration.preload_path` (default: `db/seed/preload`).

### Example Usage

```ruby
BetterSeeder.magic(
  {
    configurations: { export_type: :sql },
    data: [
      'MyNamespace::MyModel',
      'OtherNamespace::OtherModel'
    ]
  }
)
```

This command processes each model by:

- Reading its structure file and retrieving its configuration via `seed_config`.
- Generating or fetching data according to the specified rules.
- Inserting the data into the database (if `load_data` is enabled).
- Exporting the data as an SQL file (or CSV/JSON, depending on `export_type`).

---

## Structure Generator

`BetterSeeder.generate_structure(model_name: 'MyModel')` method. This functionality automatically creates a structure file template for a given model name. The generated file is saved in the appropriate subdirectory under `db/seed/structure` and includes placeholders for attribute generators, a validation schema, seed configuration, and uniqueness constraints.

### How to Use

Simply call the method with your model name. For example:

```ruby
BetterSeeder.generate_structure(model_name: 'MyNamespace::MyModel')
```

This command will generate a file at `db/seed/structure/my_namespace/my_model_structure.rb`.

### Example Generated File

The generated file will contain a template similar to the following:

```ruby
module MyNamespace
  class MyModelStructure < BetterSeeder::StructureBase
    # Defines generators for each attribute.
    def self.structure
      {
        attribute_name: [:string, -> { "your value" }]
      }
    end

    # Optional: Validate generated records using Dry-schema.
    def self.seed_schema
      Dry::Schema.Params do
        required(:attribute_name).filled(:string)
      end
    end

    # Specific seeding configuration for MyModel.
    def self.seed_config
      {
        file_name: 'my_model_seed',
        columns: { excluded: [] },
        generate_data: true,
        count: 10,
        load_data: true,
        parent: nil
      }
    end

    # Optional: Uniqueness constraints.
    def self.unique_keys
      []
    end
  end
end
```

### Benefits

- **Automated Scaffolding:** Quickly generate a complete structure file template for any model.
- **Consistency:** All generated files adhere to a standard format, ensuring consistency across your seeding logic.
- **Customization:** Easily modify the generated file to fine-tune attribute generators, validation rules, seeding configuration, and uniqueness constraints.

---

## Conclusion

BetterSeeder provides a modular, configurable, and extensible system for seeding your Rails application's data:

- **Centralized Configuration:**  
  Configure paths and logging via a Rails initializer.

- **Modular Structure Files:**  
  Define generation, validation, and configuration logic for each model in dedicated structure files.

- **Seamless Data Handling:**  
  Automatically generate, validate, load, and export seed data with support for parent/child relationships and various export formats.

For further details or contributions, please refer to the official repository or documentation.