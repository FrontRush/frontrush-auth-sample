Rails.application.config.middleware.use OmniAuth::Builder do
       #This points to the frontrush staging server
	provider :frontrush, consumer_key: 'key3', consumer_secret: 'secret3', frontrush_url: 'http://frontrushrails.pleaserecruit.me/FRConnectServices', setup: true
end
