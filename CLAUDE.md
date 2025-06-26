# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pulse Zero is a Ruby gem that generates a complete real-time broadcasting system for Rails applications using Inertia.js and React. It follows a "zero dependency" philosophy where all code is generated into the target application rather than being a runtime dependency.

## Common Commands

### Development
```bash
# Install dependencies
bundle install

# Run all tests and linting (default)
rake

# Run tests only
rake test

# Run a specific test file
ruby -Itest test/test_install_generator.rb

# Run tests with verbose output
rake test TESTOPTS="--verbose"

# Run code style checks
rake rubocop

# Build the gem
rake build

# Install gem locally for testing
rake install

# Release to RubyGems (maintainers only)
rake release
```

### Generator Testing
```bash
# Test the generator in a Rails app
rails generate pulse_zero:install
```

## Architecture Overview

### Core Philosophy
- **Generator-only**: The gem generates all code into the user's Rails application
- **Zero runtime dependencies**: Generated code doesn't depend on the gem after installation
- **Full ownership**: Users can modify all generated code

### Project Structure
```
pulse_zero/
├── lib/
│   ├── pulse_zero.rb                    # Gem entry point
│   ├── pulse_zero/
│   │   ├── engine.rb                    # Rails engine configuration
│   │   └── version.rb                   # Version constant (0.3.0)
│   └── generators/
│       └── pulse_zero/
│           └── install/
│               ├── install_generator.rb  # Main generator logic
│               └── templates/           # Code templates
│                   ├── backend/         # Ruby/Rails templates
│                   └── frontend/        # TypeScript/React templates
└── test/                               # Minitest suite
```

### Generator Flow
1. **Prerequisites Check**: Verifies ActionCable and Inertia.js setup
2. **Backend Generation**: Creates files in `lib/pulse/`, controllers, models, channels, and jobs
3. **Frontend Generation**: Creates TypeScript WebSocket management and React hooks
4. **Configuration**: Updates routes, autoload paths, and ApplicationController
5. **Documentation**: Generates usage guide at `docs/PULSE_USAGE.md`

### Key Components Generated
- **Backend**: `Pulse::Broadcaster` for Rails-side broadcasting
- **Frontend**: `PulseWebSocket` class for connection management
- **React Hooks**: `usePulseWebSocket` and `usePulseListener` for easy integration
- **Security**: Signed streams for secure channel subscriptions

## Testing Approach

### For Gem Development
- Tests verify that all template files exist and can be generated
- No runtime tests (users test their own generated code)
- Must pass RuboCop linting (max line length: 120, double quotes for strings)
- CI tests against Ruby 3.0-3.3 and Rails 7.0-7.2

### For Generated Code (in user's app)
- Use `assert_broadcast_on` for testing broadcasts
- Use `suppressing_pulse_broadcasts` block to disable broadcasts in tests
- Enable debug logging: `localStorage.setItem('PULSE_DEBUG', 'true')`

## Important Notes
- Target Ruby version: >= 3.0.0
- Rails compatibility: >= 7.0, < 9
- Required: ActionCable and Inertia.js with React
- When modifying templates, ensure they work across all supported Rails versions
- The gem version is defined in `lib/pulse_zero/version.rb`