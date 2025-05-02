source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.0"

# Core frameworks
gem "rails", "~> 7.1.2"
gem "puma", "~> 6.4"
gem "pg", "~> 1.5"
gem "redis", "~> 5.0"

# Asset pipeline and frontend
gem "sprockets-rails"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "view_component"
gem "jbuilder"

# Authentication & Authorization
gem "devise"
gem "pundit"
gem "jwt"
gem "rack-attack"
gem "paper_trail"
gem "attr_encrypted"

# API & Data processing
gem "aws-sdk-comprehend" # Para análise de sentimentos
gem "sentimental"        # Alternativa mais leve para análise de sentimentos
gem "pagy"               # Paginação
gem "ransack"            # Buscas avançadas
gem "active_storage_validations"
gem "image_processing"

# Background processing & scheduling
gem "sidekiq"
gem "sidekiq-scheduler"
gem "noticed"           # Sistema de notificações

# Monitoring & Error tracking
gem "sentry-ruby"
gem "sentry-rails"
gem "lograge"

# Data visualization
gem "chartkick"
gem "groupdate"

# Web Push Notifications
gem "webpush"

# I18n & Localization
gem "rails-i18n"
gem "devise-i18n"

# Security
gem "strong_migrations"
gem "brakeman", require: false

# Deployment
gem "dockerfile-rails", ">= 1.5", group: :development

# Development & test gems
group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "pry-rails"
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "dotenv-rails"
end

group :development do
  gem "web-console"
  gem "rack-mini-profiler"
  gem "spring"
  gem "annotate"
  gem "letter_opener"
  gem "bullet" # Detecta N+1 queries
  gem "rails-erd" # Gera diagramas de modelo ER
  gem "solargraph", require: false # Intellisense para Ruby
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
  gem "shoulda-matchers"
  gem "simplecov", require: false
  gem "webmock"
  gem "vcr"
end

# Production gems
group :production do
  gem "aws-sdk-s3", require: false
  gem "rack-timeout"
  gem "redis-session-store"
  gem "newrelic_rpm"
  gem "scout_apm"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

# Use Active Storage variants
gem "aws-sdk-s3", require: false