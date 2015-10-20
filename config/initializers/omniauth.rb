Rails.application.config.middleware.use OmniAuth::Builder do
       #This points to the frontrush staging server
	provider :frontrush, consumer_key: 'fake_key', consumer_secret: 'fake_secret', frontrush_url: 'http://frontrushtest.dyndns.org/FRConnectServices', setup: true
end	

