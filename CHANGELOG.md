# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.2] - 2025-06-26

### Changed
- Updated README.md with clearer explanations and better examples
- Improved post-installation message to reflect README content
- Enhanced PULSE_USAGE.md template with philosophy and comprehensive examples
- Reorganized project documentation structure

### Removed
- Removed redundant SUMMARY.md and FIX_SUMMARY.md files
- Moved EXAMPLES.md to docs/ directory for cleaner project root

## [0.3.1] - 2025-06-26

### Fixed
- Fixed RuboCop linting issues

### Changed
- Minor documentation improvements

## [0.3.0] - 2025-01-26

### Changed
- Moved all frontend library files from `app/frontend/lib/` to `app/frontend/lib/pulse/` subdirectory
- Updated all import paths in hooks to reference the new location
- This provides better organization and avoids naming conflicts with other libraries

### Fixed
- Updated documentation to reflect new import paths

## [0.2.2] - 2025-01-26

### Fixed
- Fixed WebSocket subscription parameter name in pulse.ts (changed from `signed_stream_name` to `"signed-stream-name"`)
- This fixes the issue where broadcasts were sent but not received by the frontend

## [0.2.1] - 2025-01-26

### Fixed
- Fixed "uninitialized constant Pulse" error on Rails startup
- Generator now properly sets up autoload paths for lib directory
- Made initializer defensive by checking if Pulse is defined
- Removed conditional engine loading from pulse.rb template
- Added setup_autoload_paths step to generator execution flow
- Fixed ApplicationCable connection to not assume authentication is configured
- Default connection now accepts all connections with guest identifiers

### Changed
- ApplicationCable::Connection template now provides safe default that accepts all connections
- Added comprehensive authentication examples (Devise, Session, JWT) in documentation
- Generator now warns about authentication configuration requirement
- Improved documentation with authentication setup section

## [0.2.0] - 2025-01-26

### Changed
- Complete rewrite of templates to match actual implementation
- Use `mattr_accessor :config` instead of thread-local variables
- Use `Pulse.config` for all configuration
- Match exact broadcast API with keyword arguments
- BroadcastJob now accepts named parameters (streamables:, event:, payload:, request_id:)
- ThreadDebouncer uses instance-based approach with `.for(key)`
- StreamName module uses `extend self` pattern
- Channel uses hyphenated parameter names ("signed-stream-name")
- Documentation shows both direct broadcasting and DSL approaches

### Fixed
- Exact match with production code patterns
- Proper configuration in initializer using Pulse.config
- Correct parameter passing to broadcast methods

## [0.1.1] - 2025-01-26

### Fixed
- Create `app/frontend/types/index.ts` if it doesn't exist instead of failing
- Prevent duplicate injection of `pulse_request_id` in Current model
- Prevent duplicate inclusion of `Pulse::RequestIdTracking` in ApplicationController

## [0.1.0] - 2025-01-26

### Added
- Initial release of Pulse Zero
- Rails generator for installing real-time broadcasting system
- Backend components:
  - Core Pulse module with stream verification
  - Rails Engine for isolation
  - Broadcasting system with CRUD events
  - Model concern with `broadcasts_to` DSL
  - ActionCable channel for WebSocket subscriptions
  - Background job for async broadcasting
  - Request ID tracking for correlation
- Frontend components (TypeScript):
  - Subscription manager
  - Connection monitor with exponential backoff
  - Recovery strategy for browser tab suspension
  - Visibility manager for tab focus handling
  - React hooks: `usePulse` and `useVisibilityRefresh`
- Comprehensive documentation
- Test helpers and examples

[Unreleased]: https://github.com/darkamenosa/pulse-zero/compare/v0.3.2...HEAD
[0.3.2]: https://github.com/darkamenosa/pulse-zero/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/darkamenosa/pulse-zero/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/darkamenosa/pulse-zero/compare/v0.2.2...v0.3.0
[0.2.2]: https://github.com/darkamenosa/pulse-zero/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/darkamenosa/pulse-zero/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/darkamenosa/pulse-zero/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/darkamenosa/pulse-zero/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/darkamenosa/pulse-zero/releases/tag/v0.1.0