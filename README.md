![BetterSeeder Logo](logo.png)

# BetterSeeder 🌱

[![Gem Version](https://badge.fury.io/rb/better_seeder.svg)](https://badge.fury.io/rb/better_seeder)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ruby Style Guide](https://img.shields.io/badge/code_style-rubocop-brightgreen.svg)](https://github.com/rubocop/rubocop)

> 🚀 A powerful Ruby gem for structured, efficient, and maintainable database seeding in Rails applications

BetterSeeder simplifies the process of generating, validating, and loading seed data in your Rails applications. It provides a structured approach to define and manage seed data, making your seeding process more maintainable and efficient.

## Statistics

Below are two images displaying key statistics from the seeding process:

- **Initial Generation Statistics:**  
  This chart represents metrics from the very first generation run.

![Initial Generation Statistics](generate.png)

- **Reload Data Statistics:**  
  This chart shows the metrics after reloading data (from the SQL file) into the database.

![Reload Data Statistics](reload.png)

✨ **Key Features**
- 🏗️ **Structured Data Generation**: Define model-specific structure files
- ✅ **Data Validation**: Validate generated data using Dry::Schema
- 🔄 **Uniqueness Constraints**: Enforce uniqueness across one or multiple columns
- 📊 **Progress Tracking**: Real-time progress bars during data generation
- 📦 **Multiple Export Formats**: Export data as SQL, CSV, or JSON
- 👨‍👧‍👦 **Parent/Child Relationships**: Support for complex data relationships
- 🔍 **Preflight Data**: Define specific records to be inserted before dynamic generation

## Why BetterSeeder? 🤔

- 🏗️ **Structured Approach**: Centralize your seeding logic in dedicated structure files
- 🧩 **Modular Design**:
  - Separate model-specific logic
  - Reusable data generators
  - Configurable validation rules
- 🔄 **Flexible Data Generation**:
  - Dynamic data generation with FFaker
  - Support for custom generators
  - Parent/child relationships
- ✅ **Robust Validation**:
  - Schema validation with Dry::Schema
  - Uniqueness constraints
  - Custom validation rules
- 📊 **Visibility & Control**:
  - Real-time progress tracking
  - Detailed logging
  - Configurable output formats
- 👨‍👧‍👦 **Relationship Management**:
  - Parent/child record generation
  - Foreign key handling
  - Multiple child records per parent

## Installation

Add the gem to your Gemfile:

```ruby
gem 'better_seeder', '~> 0.2.6'
```

Then run:

```bash
bundle install
```

Or install the gem manually:

```bash
gem install better_seeder
```

## Configuration

In a Rails application, you can create an initializer by running:

```ruby
BetterSeeder.install
```

This command creates the file `config/initializers/better_seeder.rb` with a default configuration. An example configuration is:

```ruby
BetterSeeder.configure do |config|
  # Language for logs (default: :en)
  config.log_language = :en

  # Log level (default: :info)
  config.log_level = :info

  # Path to structure files (default: Rails.root.join('db', 'seed', 'structure'))
  config.structure_path = Rails.root.join('db', 'seed', 'structure')

  # Path to preloaded data (default: Rails.root.join('db', 'seed', 'preload'))
  config.preload_path = Rails.root.join('db', 'seed', 'preload')
end
```

## Structure Files

For each model, create a structure file that centralizes the logic for generating, validating, and configuring seed data. Each structure file should include:

### Core Components

- **`structure`**  
  Defines how each attribute is generated:
  ```ruby
  def self.structure
    {
      name:       [:string,   -> { FFaker::Name.name }],
      email:      [:string,   -> { FFaker::Internet.email }],
      created_at: [:datetime, -> { Time.zone.now }]
    }
  end
  ```

- **`seed_schema_validation` (Optional)**  
  Validates generated records using Dry::Schema:
  ```ruby
  def self.seed_schema_validation
    Dry::Schema.Params do
      required(:name).filled(:string)
      required(:email).filled(:string)
      required(:created_at).filled(:time)
    end
  end
  ```

- **`seed_config`**  
  Configures the seeding process:
  ```ruby
  def self.seed_config
    {
      file_name: 'my_model_seed',
      columns: { excluded: [:id, :updated_at] },
      generate_data: true,
      count: 50,
      load_data: true,
      parents: [
        { model: ::MyNamespace::ParentModel, column: :parent_id }
      ],
      childs: {
        count: 3,
        attributes: {
          some_attribute: ['value1', 'value2', 'value3']
        }
      }
    }
  end
  ```

### Additional Components

- **`unique_keys` (Optional)**  
  Defines uniqueness constraints:
  ```ruby
  def self.unique_keys
    [[:email], [:first_name, :last_name]]
  end
  ```

- **`preflight` (Optional)**  
  Provides specific records to insert before dynamic generation:
  ```ruby
  def self.preflight
    [{ name: 'Admin User', email: 'admin@example.com', created_at: Time.zone.now }]
  end
  ```

- **`foreign_data` (Optional)**  
  Provides data for foreign key relationships:
  ```ruby
  def self.foreign_data
    @foreign_data ||= {
      parents: ::Parent.all,
      categories: ::Category.all
    }
  end
  ```

## Usage

### Basic Usage

```ruby
BetterSeeder.magic(
  model_names: ['MyNamespace::MyModel', 'AnotherNamespace::AnotherModel'],
  configurations: {
    export_type: :sql
  }
)
```

### Structure Generation

To generate a structure file template for a model:

```ruby
BetterSeeder.generate_structure(model_name: 'MyNamespace::MyModel')
```

This creates a file at `db/seed/structure/my_namespace/my_model_structure.rb` with placeholders for all required methods.

### Rails Generator

Alternatively, use the Rails generator:

```bash
rails generate better_seeder:structure MyNamespace::MyModel
```

## Advanced Features

### Child Record Generation

BetterSeeder supports generating multiple child records for each parent record. In your model's seed configuration, define a `childs` section:

```ruby
def self.seed_config
  {
    # ... other configuration
    childs: {
      count: 3,  # Generate 3 child records per parent
      attributes: {
        role: ['admin', 'editor', 'viewer']  # Each child gets a different role
      }
    }
  }
end
```

This allows for a total record count equal to *(parent count) × (child count)*.

### Preflight Data

You can define specific records to be inserted before dynamic generation:

```ruby
def self.preflight
  [
    { name: 'Admin User', email: 'admin@example.com', role: 'admin' },
    { name: 'System User', email: 'system@example.com', role: 'system' }
  ]
end
```

These preflight records count toward the total defined in `seed_config[:count]`.

## Example Structure File

```ruby
# db/seed/structure/my_namespace/my_model_structure.rb
module MyNamespace
  class MyModelStructure < ::BetterSeeder::Structure::Utils
    def self.structure
      {
        name:       [:string,   -> { FFaker::Name.name }],
        email:      [:string,   -> { FFaker::Internet.email }],
        role:       [:enum,     -> { %w[admin editor viewer].sample }],
        created_at: [:datetime, -> { Time.zone.now }]
      }
    end

    def self.seed_schema_validation
      Dry::Schema.Params do
        required(:name).filled(:string)
        required(:email).filled(:string)
        required(:role).filled(:string)
        required(:created_at).filled(:time)
      end
    end

    def self.seed_config
      {
        file_name: 'my_model_seed',
        columns: { excluded: [:id, :updated_at] },
        generate_data: true,
        count: 50,
        load_data: true,
        parents: [
          { model: ::MyNamespace::ParentModel, column: :parent_id }
        ],
        childs: {
          count: 3,
          attributes: {
            role: ['admin', 'editor', 'viewer']
          }
        }
      }
    end

    def self.preflight
      [{ name: 'Admin User', email: 'admin@example.com', role: 'admin', created_at: Time.zone.now }]
    end

    def self.unique_keys
      [[:email]]
    end
  end
end
```

## How It Works

When you call `BetterSeeder.magic` with a configuration that contains an array of model names, the gem will:

1. **Load Structure Files**  
   Retrieve the corresponding structure file for each model.

2. **Process Preflight Data**  
   If a `preflight` method is defined, its returned records will be inserted first.

3. **Generate Dynamic Data**  
   Use the `structure` method to generate data dynamically.

4. **Validate Generated Data**  
   Validate records using `seed_schema_validation` if defined.

5. **Enforce Uniqueness**  
   Ensure uniqueness based on `unique_keys`.

6. **Handle Relationships**  
   Process parent/child relationships and foreign keys.

7. **Load Data**  
   Insert records into the database if `load_data` is true.

8. **Export Data**  
   Export data in the specified format (SQL, CSV, or JSON).

## Contributing 🤝

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Contact & Support 📬

- **Email**: alessio.bussolari@pandev.it
- **Issues**: [GitHub Issues](https://github.com/alessiobussolari/better_seeder/issues)

## License 📄

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details.

BetterSeeder aims to simplify the database seeding process in Rails applications by providing a structured, configurable, and extensible system. Whether you need to generate dynamic data, validate it, or handle complex relationships, BetterSeeder streamlines the entire process. Contributions, feedback, and feature requests are highly encouraged to help improve the gem further.

For more details, please visit the [GitHub repository](https://github.com/alessiobussolari/better_seeder).
