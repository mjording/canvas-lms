require File.expand_path('../application', __FILE__)


# Initialize the rails application
if !!ENV['CANVAS_RAILS3'] || File.exist?(File.expand_path("../../RAILS3", __FILE__))
  def environment_configuration(_config)
    CanvasRails::Application.configure do
      yield(config)
    end
  end

  # Load the rails application
  CanvasRails::Application.initialize!
  
else
  def environment_configuration(config)
    yield(config)
  end

  # Bootstrap the Rails environment, frameworks, and default configuration
  require File.expand_path('../boot', __FILE__)

  Rails::Initializer.run do |config|
    eval(File.read(File.expand_path("../shared_boot.rb", __FILE__)), binding, "config/shared_boot.rb", 1)
  end
end
