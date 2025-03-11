# Changelog

All notable changes to BetterSeeder will be documented in this file.

## [0.2.6] - 2025-03-11

### Changed
- Simplified the system by removing experimental features to improve stability
- Removed parallel processing support to enhance reliability
- Removed data caching system for more predictable behavior
- Removed batch record loading in favor of traditional record-by-record insertion
- Reverted to the basic validation system with Dry::Schema
- Simplified logging and reporting system for better clarity

## [0.2.5] - 2025-03-04

### Fixed
- Fixed issues with `insert_all!` when handling tables with composite primary keys
- Resolved errors related to undefined columns when querying records

### Added
- Added support for preflight data insertion
- Improved error handling for database operations

## [0.2.4] - 2025-02-15

### Added
- Added experimental support for parallel processing
- Implemented caching for generated records
- Added batch loading capabilities
- Enhanced validation with support for relationships
- Added detailed statistical reporting

### Fixed
- Fixed issues with configuration validation
- Resolved memory leaks during large data generation

## [0.2.3] - 2025-01-20

### Added
- Added support for child record generation
- Implemented uniqueness constraints across multiple columns
- Added progress bar visualization during data generation

### Fixed
- Fixed issues with foreign key relationships
- Resolved memory consumption issues during large data sets generation

## [0.2.2] - 2025-01-05

### Added
- Added support for multiple export formats (SQL, CSV, JSON)
- Implemented structure file generation via Rails generator
- Added initializer installation command

### Fixed
- Fixed issues with data type conversion
- Resolved configuration loading problems

## [0.2.1] - 2024-12-15

### Added
- Added validation using Dry::Schema
- Implemented uniqueness constraints
- Added support for parent/child relationships

### Fixed
- Fixed issues with Rails integration
- Resolved data generation performance bottlenecks

## [0.2.0] - 2024-12-01

### Added
- Initial release of BetterSeeder
- Basic data generation capabilities
- Simple validation system
- Database loading functionality
- Export to SQL format
