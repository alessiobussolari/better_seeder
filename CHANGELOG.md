# Changelog

## [0.2.5] - 2025-03-04

### Added
- Introduced preflight functionality: If a structure file defines a `preflight` method, its returned records are inserted first, counting toward the total record count define

## [0.2.4] - 2025-03-03

### Added
- Added functionality in the Farmer class to generate child records per parent. With a childs configuration that defines a count and attribute arrays, the seeder creates (parent count) × (childs count) records, assigning distinct attribute values for each child.

## [0.2.3.1] - 2023-10-12

### Fixed
- Minor fixes.

### Added
- Added Rubocop integration.

## [0.2.3] - 2025-02-11

### Changed
- Optimized the entire system for improved performance and a more modular seeding process.
- Refactored `Farmer` class methods for better readability and modularity.
- Introduced the `log_level` configuration for more precise logging control.
- Improved parent key injection with a new configuration structure (e.g., `parents: [{ model: ::Media::Media, column: :media_id }, { model: ::Creators::Creator, column: :creator_id }]`).
- Enhanced the schema validation process.
- Added SQL-based data loading (triggered when `load_data` is true) to load existing seed data from a SQL file, preventing unnecessary record creation.
- Enhanced export functionality in the seeding workflow to support additional formats.

## [0.2.2] - 2025-02-10

### Changed
- Renamed the `generators` directory to `builders` to avoid naming clashes.
- Updated all related references and commands to use the new `builders` namespace.

## [0.2.1] - 2025-02-10

### Fixed
- **Custom Generator Loading:**  
  Fixed an issue where the custom generator `better_seeder:structure` was not found. The file structure and namespace for the generator have been updated so that Rails can correctly load it. Now you can run:
  ```bash
  rails generate better_seeder:structure MyNamespace::MyModel

## [0.2.0] - 2025-02-10

### Added
- **Structure Generator:**  
  Introduced the `BetterSeeder.generate_structure(model_name: 'MyModel')` method. This new functionality automatically creates a structure file template for a given model name. The generated file is saved in the appropriate subdirectory under `db/seed/structure` and includes placeholders for attribute generators, validation schema, seed configuration, and uniqueness constraints.

## [0.1.1] - 2025-02-10

### Fixed
- Updated ActiveSupport and ActiveRecord dependency constraints from "~> 4.2" to ">= 4.2" to ensure compatibility with newer Rails versions.

## [0.1.0] - 2025-02-10

### Added
- **Initial Release of BetterSeeder**
    - Released the initial version of **BetterSeeder**, a modular Rails gem for seeding data.
- **Dynamic Data Generation**
    - Added support for defining structure files for each model to generate dynamic seed data.
- **Data Validation**
    - Integrated Dry-schema to validate generated records.
- **Uniqueness Constraints**
    - Implemented enforcement of uniqueness constraints for both single and multi-column keys.
- **Loading & Exporting**
    - Enabled loading of generated seed data directly into the database (with support for parent/child relationships).
    - Added export functionality for multiple formats: SQL (with a single bulk INSERT), CSV, and JSON.
- **Centralized Configuration**
    - Introduced a centralized configuration via a Rails initializer to set parameters such as `log_language`, `structure_path`, and `preload_path`.
- **Automatic Initializer Installation**
    - Provided a `BetterSeeder.install` method to automatically create the initializer file in your Rails app.
- **Exporters and BaseExporter**
    - Created a BaseExporter that centralizes common file output logic.
    - Implemented specific exporters: `Sql`, `Csv`, and `Json`.
- **Dependencies Integration**
    - Integrated essential dependencies including `ffaker`, `dry-schema`, `dry-types`, `ruby-progressbar`, along with Rails components (`activesupport` and `activerecord`).
