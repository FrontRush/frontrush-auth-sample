Rails.application.config.middleware.use OmniAuth::Builder do
	provider :frontrush, consumer_key: 'key3', consumer_secret: 'secret3', frontrush_url: 'http://frontrushtest.dyndns.org/FRConnectServices', setup: true
end	
