Rails.configuration.stripe = {
  publishable_key: "#{Rails.application.credentials[:stripe][:publishable]}",
  secret_key: "#{Rails.application.credentials[:stripe][:secret]}"
}
Stripe.api_key = "#{Rails.application.credentials[:stripe][:secret]}"