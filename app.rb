# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "bcrypt"   
require "geocoder"   
require "forecast_io"
require "httparty"                                                             #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

cookclasses_table = DB.from(:cookclasses)
rsvps_table = DB.from(:rsvps)
users_table = DB.from(:users)

# enter your Dark Sky API key here
ForecastIO.api_key = "0329940053e738bed5b2dedd3528c6dd"

#Geocode API
get "/geocode" do
  view "ask"
end

get "/news" do

#Geocoder results - assign variables
    @location = params["location"]
    @results = Geocoder.search(params["location"])
    @lat_long = @results.first.coordinates # => [lat, long]
    @coordinates = "#{@lat_long[0]}, #{@lat_long[1]}"

#Geocoder Results
    @forecast = ForecastIO.forecast(@lat_long[0], @lat_long[1]).to_hash
    @current_temperature = @forecast["currently"]["temperature"]
    @conditions = @forecast["currently"]["summary"]


    @daily_array = @forecast["daily"]["data"]

  view "news"
end

# homepage and list of cookclasses (aka "index")
get "/" do
    puts "params: #{params}"

    @cookclasses = cookclasses_table.all.to_a
    pp @cookclasses

    view "cookclasses"
end