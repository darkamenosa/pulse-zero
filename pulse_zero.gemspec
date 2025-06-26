# frozen_string_literal: true

require_relative "lib/pulse_zero/version"

Gem::Specification.new do |spec|
  spec.name = "pulse_zero"
  spec.version = PulseZero::VERSION
  spec.authors = ["darkamenosa"]
  spec.email = ["hxtxmu@gmail.com"]

  spec.summary = "Real-time broadcasting generator for Rails + Inertia"
  spec.description = "Generate a complete real-time broadcasting system for Rails applications using " \
                     "Inertia.js with React. All code is generated into your project with zero runtime dependencies."
  spec.homepage = "https://github.com/darkamenosa/pulse_zero"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  # Use only unique URIs for each metadata key
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.glob("{lib,exe}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) } +
               %w[README.md LICENSE.txt CHANGELOG.md pulse_zero.gemspec]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 7.0", "< 9"
  spec.add_dependency "thor", "~> 1.0"

  # Development dependencies are now managed in Gemfile
end
