Sentry.init do |config|
  config.dsn = "https://dummy-token@o0.ingest.sentry.io/0"
  config.environment = Rails.env
  config.enabled_environments = %w[development test production]
  config.traces_sample_rate = 1.0
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Set a dummy release name
  config.release = "rails-sample@0.0.1"
end
