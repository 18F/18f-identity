web: bundle exec rackup config.ru --port ${PORT:-3000}
worker: bundle exec sidekiq --config config/sidekiq.yml
mail: bundle exec mailcatcher -f
