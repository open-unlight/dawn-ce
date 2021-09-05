# frozen_string_literal: true

Sentry.init do |config|
  config.breadcrumbs_logger = %i[sentry_logger http_logger]
  config.traces_sample_rate = ENV.fetch('SENTRY_SAMPLE_RATE', 1).to_f
end
