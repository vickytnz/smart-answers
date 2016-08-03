SmartAnswers::Application.configure do
  config.slimmer.logger = Rails.logger

  if Rails.env.production?
    config.slimmer.use_cache = true
  end

  config.slimmer.asset_host = "https://assets.publishing.service.gov.uk"
end
