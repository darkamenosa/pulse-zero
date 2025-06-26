require "rails/generators"
require "rails/generators/base"

module PulseZero
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def check_prerequisites
        unless defined?(ActionCable)
          say "ActionCable is required. Installing...", :yellow
          generate "action_cable:install"
        end

        unless File.exist?("app/frontend")
          say "This generator is designed for Inertia.js applications with app/frontend directory", :red
          exit 1
        end
      end

      def setup_action_cable
        # Generate base channel classes if missing
        unless File.exist?("app/channels/application_cable/connection.rb")
          template "backend/app/channels/application_cable/connection.rb.tt",
                   "app/channels/application_cable/connection.rb"
        end

        unless File.exist?("app/channels/application_cable/channel.rb")
          template "backend/app/channels/application_cable/channel.rb.tt",
                   "app/channels/application_cable/channel.rb"
        end

        # Add route if missing
        route 'mount ActionCable.server => "/cable"' unless action_cable_route_exists?
      end

      def copy_backend_files
        # Core library files
        template "backend/lib/pulse.rb.tt", "lib/pulse.rb"
        template "backend/lib/pulse/engine.rb.tt", "lib/pulse/engine.rb"
        template "backend/lib/pulse/streams/broadcasts.rb.tt", "lib/pulse/streams/broadcasts.rb"
        template "backend/lib/pulse/streams/stream_name.rb.tt", "lib/pulse/streams/stream_name.rb"
        template "backend/lib/pulse/thread_debouncer.rb.tt", "lib/pulse/thread_debouncer.rb"

        # Application files
        template "backend/app/channels/pulse/channel.rb.tt", "app/channels/pulse/channel.rb"
        template "backend/app/controllers/concerns/pulse/request_id_tracking.rb.tt",
                 "app/controllers/concerns/pulse/request_id_tracking.rb"
        template "backend/app/models/concerns/pulse/broadcastable.rb.tt",
                 "app/models/concerns/pulse/broadcastable.rb"
        template "backend/app/jobs/pulse/broadcast_job.rb.tt", "app/jobs/pulse/broadcast_job.rb"

        # Configuration
        template "backend/config/initializers/pulse.rb.tt", "config/initializers/pulse.rb"
      end

      def copy_frontend_files
        # TypeScript files in lib/pulse/
        template "frontend/lib/pulse.ts.tt", "app/frontend/lib/pulse/pulse.ts"
        template "frontend/lib/pulse-connection.ts.tt", "app/frontend/lib/pulse/pulse-connection.ts"
        template "frontend/lib/pulse-recovery-strategy.ts.tt", "app/frontend/lib/pulse/pulse-recovery-strategy.ts"
        template "frontend/lib/pulse-visibility-manager.ts.tt", "app/frontend/lib/pulse/pulse-visibility-manager.ts"

        # React hooks
        template "frontend/hooks/use-pulse.ts.tt", "app/frontend/hooks/use-pulse.ts"
        template "frontend/hooks/use-visibility-refresh.ts.tt", "app/frontend/hooks/use-visibility-refresh.ts"

        # Create or append to types/index.ts
        if File.exist?("app/frontend/types/index.ts")
          append_to_file "app/frontend/types/index.ts", pulse_types_content
        else
          create_file "app/frontend/types/index.ts", pulse_types_content
        end
      end

      def setup_current_model
        if File.exist?("app/models/current.rb")
          # Check if pulse_request_id is already defined
          current_content = File.read("app/models/current.rb")
          unless current_content.include?("pulse_request_id")
            inject_into_class "app/models/current.rb", "Current" do
              "  attribute :pulse_request_id\n"
            end
          end
        else
          template "backend/app/models/current.rb.tt", "app/models/current.rb"
        end
      end

      def setup_autoload_paths
        add_pulse_to_autoload_paths
      end

      def install_npm_dependencies
        if File.exist?("package.json")
          say "Installing @rails/actioncable...", :green
          run "npm install @rails/actioncable"
        end
      end

      def add_pulse_to_autoload_paths
        # Add lib to autoload paths
        application_file = "config/application.rb"
        application_content = File.read(application_file)

        # Add to autoload_lib if not already there
        unless application_content.include?("config.autoload_lib")
          inject_into_file application_file, after: /class Application < Rails::Application\n/ do
            <<-RUBY
    # Autoload lib directory
    config.autoload_lib(ignore: %w[assets tasks])

            RUBY
          end
        end
      end

      def setup_application_controller
        # Check if already included
        controller_content = File.read("app/controllers/application_controller.rb")
        unless controller_content.include?("Pulse::RequestIdTracking")
          inject_into_class "app/controllers/application_controller.rb",
                            "ApplicationController" do
            "  include Pulse::RequestIdTracking\n"
          end
        end
      end

      def create_documentation
        template "docs/PULSE_USAGE.md.tt", "docs/PULSE_USAGE.md"

        say "\n✅ Pulse real-time broadcasting has been installed!", :green
        say "\n⚠️  IMPORTANT: Configure authentication!", :yellow
        say "The default ApplicationCable connection accepts all connections."
        say "Edit app/channels/application_cable/connection.rb to add your authentication logic."
        say "\nNext steps:", :yellow
        say "1. Configure authentication in app/channels/application_cable/connection.rb"
        say "2. Read docs/PULSE_USAGE.md for complete setup instructions"
        say "3. Add 'include Pulse::Broadcastable' to models that need broadcasting"
        say "4. Use 'usePulse' hook in your React components"
        say "\nExample:", :blue
        say <<~EXAMPLE
          # In your model:
          class Post < ApplicationRecord
            include Pulse::Broadcastable
            broadcasts_to ->(post) { [post.account, "posts"] }
          end

          # In your controller:
          @pulse_stream = Pulse::Streams::StreamName.signed_stream_name([Current.account, "posts"])

          # In your React component:
          usePulse(pulseStream, (message) => {
            router.reload({ only: ['posts'] })
          })
        EXAMPLE
      end

      private

      def action_cable_route_exists?
        routes_file = File.read("config/routes.rb")
        routes_file.include?("ActionCable.server") || routes_file.include?("action_cable")
      end

      def pulse_types_content
        <<~TYPES

          // Pulse Types
          export interface PulseMessage {
            event: 'created' | 'updated' | 'deleted' | 'refresh'
            payload: any
            requestId?: string
            at: number
          }

          export interface PulseSubscription {
            unsubscribe: () => void
          }
        TYPES
      end
    end
  end
end
