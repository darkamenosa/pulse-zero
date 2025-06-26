module PulseZero
  # Only define the engine if Rails is loaded
  if defined?(Rails::Engine)
    class Engine < ::Rails::Engine
      isolate_namespace PulseZero
    end
  end
end
