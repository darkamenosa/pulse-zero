# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "minitest/autorun"

# Don't load Rails during tests
ENV["PULSE_ZERO_TESTING"] = "true"

require "pulse_zero"
