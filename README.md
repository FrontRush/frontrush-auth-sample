#Overview
This is a simple rails app that uses the Front Rush Omniauth Gem https://rubygems.org/gems/omniauth-frontrush. To run this app, you just need to...

1. update **config/initializers/omniauth.rb** with the corresponding credentials.
2. run `rails s` and go to **localhost:3000**


## Front Rush Omniauth
This uses Front Rush Omniauth which is a library for authorizing coaches through Front Rush and then posting recruit data to the respective coaches account in Front Rush. We have implemented an omniauth gem based upon https://github.com/intridea/omniauth. The documentation is nearly identical with the exception of the OmniAuth callback (outlined below) and the request for posting to Front Rush which does exist in Omniauth. Another implementation example can be found at http://railscasts.com/episodes/241-simple-omniauth?view=asciicast.

## Implementation

Add the omniauth gem to your Gemfile.
  ```
  Gemfile
  
  gem 'omniauth-frontrush'
  ```

Create an omniauth initializer and include your consumer_key and consumer_secret that we will provide to you.
  ```config/initializers/omniauth.rb
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :frontrush, consumer_key: 'fake_key', consumer_secret: 'fake_secret', frontrush_url: 'url provided by frontrush',   setup: true
  end
  ```

Create a route for the Front Rush callback.
  ```
  routes.rb
  
  get '/auth/:provider/callback', to: 'sessions#create'
  ```

Omniauth provides a callback as a hash with the relative data for the coach who is signing in. Below is an example using a Sessions controller.
```
  sessions_controller.rb
  
  class SessionsController < ApplicationController
    def create
      @user = User.find_or_create_from_auth_hash(auth_hash)
      self.current_user = @user
      redirect_to '/'
    end
    

  protected

    def auth_hash
      request.env['omniauth.auth']
    end

  end
```

You will need a view to link to the Front Rush login.
```
  /app/views/layouts/application.html.erb
  
  <div id="user_nav">
    <%= link_to "Sign in with Front Rush", "/auth/frontrush" %>
  </div>
```  

###auth_hash
The service will return an auth_hash with relevant info about the user.
- **oauth_token** the token you will use for posting athlete data to Front Rush.
- **Email** the coach's email address in Front Rush.
- **Sports** an array that includes the sport info for the coach. A coach may have access to multiple sports so this is can be used for presenting a drop-down for the coach to choose which sport they would like to post data to.
- **SportName** the name of the sport that the coach has access to in Front Rush. This is customizable by the coach.
- **SportID** the id for the sport that you will use later when posting json to Front Rush.
- **University** university info for that Coach.
- **provider** this will be "frontrush"


  ```
  auth_hash = <OmniAuth::AuthHash credentials=#<OmniAuth::AuthHash oauth_token="fake_oauth_token" oauth_token_secret="fake_oauth_token"> extra=#<OmniAuth::AuthHash Email="coach@university.edu" Sports=[#<OmniAuth::AuthHash SportName="Baseball" SportID="123">, #<OmniAuth::AuthHash SportName="Football" SportID="1234">, #<OmniAuth::AuthHash SportName="Soccer" SportID="1235">] Token="fake_token" TokenSecret="fake_token" University=#<OmniAuth::AuthHash UniversityName="University"> info=#<OmniAuth::AuthHash::InfoHash> provider="frontrush" uid="coach@coach.edu">
```
  
#Posting to Front Rush

When posting data to Front Rush, you will post to the below address and include your consumer_key and oauth_token
```
  url = https://frontrush.com/FRConnectServices/athlete/recruit/send/profile?oauth_consumer_key='+ENV['consumer_key']+'&oauth_token='+session[:token]
```
  ```
  example.rb
  
  def post_json_to_frontrush(json_data)
    url ='https://frontrush.com/FRConnectServices/athlete/recruit/send/profile?oauth_consumer_key='+ENV['consumer_key']+'&oauth_token='+session[:token]
    uri = URI.parse(url)
    make_post_request(uri,json_data)
  end

  def make_post_request(uri,json_data)
    response = nil
    Net::HTTP.start( uri.host,uri.port) { | http |
      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "text\plain"
      request.body = json_data
      response = http.request(request)
    }
    return response
  end
  ```
  
![alt text](http://g.recordit.co/YfExOq3YJ3.gif "Oauth Flow")


