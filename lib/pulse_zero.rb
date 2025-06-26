# frozen_string_literal: true

require_relative "pulse_zero/version"

module PulseZero
  class Error < StandardError; end

  # Autoload the engine only when Rails is available
  autoload :Engine, "pulse_zero/engine"
end

# Load the engine if Rails is already loaded
require_relative "pulse_zero/engine" if defined?(Rails)
