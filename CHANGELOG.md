# Changelog

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
