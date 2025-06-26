require "test_helper"
require "fileutils"
require "tmpdir"

class TestInstallGenerator < Minitest::Test
  def test_generator_exists
    # Just check that we can load the generator file
    generator_path = File.expand_path("../lib/generators/pulse_zero/install/install_generator.rb", __dir__)
    assert File.exist?(generator_path), "Generator file should exist"
  end

  def test_template_files_exist
    templates_dir = File.expand_path("../lib/generators/pulse_zero/install/templates", __dir__)

    # Check backend templates
    backend_files = [
      "backend/lib/pulse.rb.tt",
      "backend/lib/pulse/engine.rb.tt",
      "backend/lib/pulse/streams/broadcasts.rb.tt",
      "backend/lib/pulse/streams/stream_name.rb.tt",
      "backend/lib/pulse/thread_debouncer.rb.tt",
      "backend/app/channels/pulse/channel.rb.tt",
      "backend/app/controllers/concerns/pulse/request_id_tracking.rb.tt",
      "backend/app/models/concerns/pulse/broadcastable.rb.tt",
      "backend/app/jobs/pulse/broadcast_job.rb.tt",
      "backend/app/models/current.rb.tt",
      "backend/config/initializers/pulse.rb.tt"
    ]

    backend_files.each do |file|
      assert File.exist?(File.join(templates_dir, file)), "Template #{file} should exist"
    end

    # Check frontend templates
    frontend_files = [
      "frontend/lib/pulse.ts.tt",
      "frontend/lib/pulse-connection.ts.tt",
      "frontend/lib/pulse-recovery-strategy.ts.tt",
      "frontend/lib/pulse-visibility-manager.ts.tt",
      "frontend/hooks/use-pulse.ts.tt",
      "frontend/hooks/use-visibility-refresh.ts.tt"
    ]

    frontend_files.each do |file|
      assert File.exist?(File.join(templates_dir, file)), "Template #{file} should exist"
    end

    # Check docs
    assert File.exist?(File.join(templates_dir, "docs/PULSE_USAGE.md.tt")), "Documentation template should exist"
  end

  def test_all_template_files_are_valid
    templates_dir = File.expand_path("../lib/generators/pulse_zero/install/templates", __dir__)

    Dir.glob(File.join(templates_dir, "**/*.tt")).each do |template_file|
      content = File.read(template_file)
      # Basic check that the file is not empty
      refute content.strip.empty?, "Template #{template_file} should not be empty"

      # Check that Ruby files have valid syntax (basic check)
      if template_file.end_with?(".rb.tt")
        assert content.include?("module") || content.include?("class") || content.include?("Rails"),
               "Ruby template #{template_file} should contain valid Ruby code"
      end

      # Check that TypeScript files have valid syntax (basic check)
      if template_file.end_with?(".ts.tt")
        assert content.include?("export") || content.include?("import") || content.include?("interface") || content.include?("function"),
               "TypeScript template #{template_file} should contain valid TypeScript code"
      end
    end
  end
end
