require File.expand_path('../boot', __FILE__)
require 'rails/all'

Bundler.require(*Rails.groups)

APP_NAME = 'login.gov'.freeze

module Upaya
  class Application < Rails::Application
    config.active_job.queue_adapter = :sidekiq
    config.active_record.raise_in_transactional_callbacks = true
    config.autoload_paths << Rails.root.join('app/mailers/concerns')
    config.time_zone = 'UTC'
    config.middleware.use Rack::Attack
    config.browserify_rails.commandline_options = '-t [ babelify --presets [ es2015 ] ]'
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{yml}')]

    routes.default_url_options[:host] = Figaro.env.mailer_domain_name
  end
end
