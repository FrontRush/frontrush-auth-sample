#Overview
This is a simple rails app that uses the Front Rush Omniauth Gem https://rubygems.org/gems/omniauth-frontrush. To run this app, you just need to...

1. update **config/initializers/omniauth.rb** with the corresponding credentials.
2. run `rails s` and go to **localhost:3000**


## Front Rush Omniauth
This uses Front Rush Omniauth which is a library for authorizing coaches through Front Rush and then posting recruit data to the respective coaches account in Front Rush. We have implemented an omniauth gem based upon https://github.com/intridea/omniauth. The documentation is nearly identical with the exception of the OmniAuth callback (outlined below) and the request for posting to Front Rush which does not exist in Omniauth. Another implementation example cane be found at http://railscasts.com/episodes/241-simple-omniauth?view=asciicast.

## Implementation

Add the omniauth gem to your Gemfile.
  ```
  # Gemfile
  
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
  # routes.rb
  
  get '/auth/:provider/callback', to: 'sessions#create'
  ```

Omniauth provides a callback as a hash with the relative data for the coach who is signing in. Below is an example using a Sessions controller.
```
  # sessions_controller.rb
  
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
  # /app/views/layouts/application.html.erb
  
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
  # example.rb
  
  ```
  def post_json_to_frontrush(json_data)
    url ='https://frontrush.com/FRConnectServices/athlete/recruit/send/profile?oauth_consumer_key='+ENV['consumer_key']+'&oauth_token='+session[:token]
    uri = URI.parse(url)
    make_post_request(uri,json_data)
  end

  def make_post_request(uri,json_data)
    response = nil
    Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == "https" ? true : false) ) { | http |
      request = Net::HTTP::Post.new(uri.request_uri)
      request["Content-Type"] = "text\plain"
      request.body = json_data
      response = http.request(request)
    }
    return response
  end
  ```
  
###JSON Overview
####General
These are General fields and are hard-coded. First Name and Last Name are required and you can choose to include any/all of the others.

**Required**
First Name / Last Name

Fields you can send...
- **FirstName, LastName** *varchar(50)*
- **EmailAddress** *varchar(100)*
- **EmailAddress2** *varchar(100). This is a second (optional) email address used for our matching algo to find duplicate records in Front Rush.*
- **CellPhone, ContactNumber** *varchar(20). You can send periods, parenthesis, etc. but best to just send numbers.*
- **Address1** *varchar(100)*
- **City, Zip** *varchar(100)*
- **State** *varchar(2)*
- **GraduationYear** *int(4)*

####Custom
This is where you send the other stuff like height, weight, favorite movie, etc...really whatever you want. They are all varchar(100) except for the LogoPath and Profile on 3rd Party Site which are varchar(500)

**Required**
LogoPath, Site Name, PartnerID

Fields you can send...
- **LogoPath** the location of your logo. If you want to send us a logo, we can give you a path that you can reference.
- **Site Name** Provided to you
- **Profile on 3rd Party Site** link back to the athletes profile 
- **PartnerID** Provided to you
- **anything else...**


####VideoDetail
This is where you can pass videos of the athletes. All fields are varchar(250). 

**Required**
VideoTitle, TimeOf, VideoLink, OutsideSource, VideoImageLogo, VideoSiteURL, VideoLocation, ThirdPartyID, PartnerID

Fields you can send...
- **VideoTitle** title of the video.
- **TimeOf** time stamp of the video.
- **VideoLink** the URL to the raw video (must be mp4).
- **OutsideSource** Provided to you
- **VideoImageLogo** the location of your logo. If you want to send us a logo, we can give you a path that you can reference.
- **VideoSiteURL** the link back to the video in your site
- **VideoLocation** the location that the video was taken.
- **ThirdPartyID** a unique ID for the video.
- **PartnerID** provided to you

####Notes
This is where you can pass notes on the athlete that the coach took.

**Required**
NotedID, NoteDate, NoteType, NoteBody

Fields you can send...
- **NoteID** a unique ID that you would pass with the note so that if the note is edited in your site then it will update in Front Rush.
- **NoteDate** the date of the note format be like 2015-10-13 20:16:26
- **NoteType** always will be "General"
- **NoteBody** is the body of the note and can be any length.

####Sports

**Required**
SportID

Fields you can send...
- **SportID** the ID for the sport that you get from the omniauth callback
- **SportName** the Name for the sport that you get from the omniauth callback

```
EXAMPLE JSON
[
    {
        "General": {
            "FirstName": "Wilson",
            "LastName": "Phillips",
            "EmailAddress": "wphillips@recruityo.com",
            "CellPhoneNumber": null,
            "ContactNumber": "123.456.789",
            "Address1": "178 Stafford Way",
            "City": "Princeton",
            "State": "NJ",
            "Zip": "08822",
            "GraduationYear": 2018
        },
        "Custom": {
            "LogoPath": "/your_logo.png",
            "Site Name": "Your Site",
            "Grade": "",
            "High School": "Princeton High School",
            "ACT": "",
            "SAT": "0",
            "GPA": "85",
            "Event Team": "Common Goal 2018 Orange",
            "Position": "Goalie",
            "Jersey Number": "3",
            "Height": "5'6\"",
            "Club Team": "",
            "Club Coach First Name": "",
            "Club Coach Last Name": "",
            "Club Coach Email": "",
            "Club Coach Cell": "",
            "Committed": "",
            "PartnerPlayerID": "yoursite222",
            "Event Seen": "IWLCA Capital Cup 2015",
            "Star Rating": null,
            "Profile on 3rd Party Site": "",
            "PartnerID": "99972010",
            "DOB": "02/09/1999"
        },
        "VideoDetail": [
            {
                "VideoTitle": "Common Goal 2018 Orange vs Elite Bel Air 2018",
                "TimeOf": "2015-07-17T17:00:00Z",
                "VideoLink": "https://s3-us-west-1.amazonaws.com/2015-capitalcup/242.mp4",
                "OutsideSource": "YourSite",
                "VideoImageLogo": "/your_logo.png",
                "VideoSiteURL": "http://localhost:3010/showcases/3015/athletes/1080507",
                "VideoLocation": "11CH",
                "ThirdPartyID": 211395,
                "PartnerID": "99972010"
            },
            {
                "VideoTitle": "Nor'easter White 2018 vs Common Goal 2018 Orange",
                "TimeOf": "2015-07-17T15:00:00Z",
                "VideoLink": "https://s3-us-west-1.amazonaws.com/2018-capitalcup/13.mp4",
                "OutsideSource": "Yoursite",
                "VideoImageLogo": "/your_logo.png",
                "VideoSiteURL": "http://localhost:3010/showcases/3015/athletes/1080507",
                "VideoLocation": "09CH",
                "ThirdPartyID": 211321,
                "PartnerID": "99972010"
            },
            {
                "VideoTitle": "Laxachusetts Elite 2018 Green vs Common Goal 2018 Orange",
                "TimeOf": "2015-07-18T14:00:00Z",
                "VideoLink": "https://s3-us-west-1.amazonaws.com/2015-capitalcup/752.mp4",
                "OutsideSource": "YourSite",
                "VideoImageLogo": "/your_logo.png",
                "VideoSiteURL": "http://localhost:3010/showcases/3015/athletes/1080507",
                "VideoLocation": "12RC",
                "ThirdPartyID": 211717,
                "PartnerID": "99972010"
            },
            {
                "VideoTitle": "Goal 2018 Orange vs Atlanta 2018",
                "TimeOf": "2015-07-18T17:00:00Z",
                "VideoLink": "https://s3-us-west-1.amazonaws.com/capitalcup/725.mp4",
                "OutsideSource": "YourSite",
                "VideoImageLogo": "/your_logo.png",
                "VideoSiteURL": "http://localhost:3010/showcases/3015/athletes/1080507",
                "VideoLocation": "12RC",
                "ThirdPartyID": 211770,
                "PartnerID": "99972010"
            }
        ],
        "Notes": [
            
        ],
        "Sports": {
            "SportID": 3375,
            "SportName": "Football"
        }
    },
    {
        "General": {
            "FirstName": "Cam",
            "LastName": "Samsonite",
            "EmailAddress": "benjones623450@yahoo.com",
            "CellPhoneNumber": "4833337914",
            "ContactNumber": "3446947123",
            "Address1": "2 Tidewater Cove",
            "City": "Pittsburgh",
            "State": "PA",
            "Zip": "21811",
            "GraduationYear": 2014
        },
        "Custom": {
            "LogoPath": "/your_logo.png",
            "Site Name": "YourSite",
            "Grade": "",
            "High School": "Stephen Decatur High School",
            "ACT": "",
            "SAT": "0",
            "GPA": "5.00",
            "Event Team": "Red 2017",
            "Position": "Mid-Field",
            "Jersey Number": "11",
            "Height": "5'6\"",
            "Club Team": "",
            "Club Coach First Name": "",
            "Club Coach Last Name": "",
            "Club Coach Email": "",
            "Club Coach Cell": "",
            "Committed": "",
            "PartnerPlayerID": "12345",
            "Event Seen": "Big Town Cup",
            "Star Rating": null,
            "Profile on 3rd Party Site": "https://yoursite/players/3272",
            "PartnerID": "99972010",
            "DOB": ""
        },
        "VideoDetail": [
            {
                "VideoTitle": "3d NE 2018 vs Denver Summit 2018",
                "TimeOf": "2015-07-18T09:00:00Z",
                "VideoLink": "https://s3-us-west-1.amazonaws.com/capitalcup/323.mp4",
                "OutsideSource": "YourSite",
                "VideoImageLogo": "/yourlogo.png",
                "VideoSiteURL": "http://yoursite/players/2838",
                "VideoLocation": "02RC",
                "ThirdPartyID": 311576,
                "PartnerID": "99972010"
            },
            {
                "VideoTitle": "Dolphins 2017 vs Long Island Top Guns 2017 Black",
                "TimeOf": "2015-07-19T13:00:00Z",
                "VideoLink": "https://s3-us-west-1.amazonaws.com/2015-capitalcup/296.mp4",
                "OutsideSource": "YourSite",
                "VideoImageLogo": "/your_logo.png",
                "VideoSiteURL": "http://yoursite/players/2838",
                "VideoLocation": "01RC",
                "ThirdPartyID": 214589,
                "PartnerID": "99972010"
            }
        ],
        "Notes": [
            {
                "NoteID": "306978",
                "NoteDate": "2015-10-13 20:16:26",
                "NoteType": "General",
                "NoteBody": "Excellent Athlete!"
            }
        ],
        "Ratings": {
        },
        "Sports": {
            "SportID": 3375,
            "SportName": "Baseball"
        }
    }
]
```
  
![alt text](http://g.recordit.co/YfExOq3YJ3.gif "Oauth Flow")


