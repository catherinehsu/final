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

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

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

# class details (aka "show")
get "/cookclasses/:id" do
    puts "params: #{params}"

    @users_table = users_table
    @cookclass = cookclasses_table.where(id: params[:id]).to_a[0]
    pp @cookclass

    @rsvps = rsvps_table.where(cookclasses_id: @cookclass[:id]).to_a
    @going_count = rsvps_table.where(cookclasses_id: @cookclass[:id], going: true).count

    view "cookclass"
end

# display the rsvp form (aka "new")
get "/cookclasses/:id/rsvps/new" do
    puts "params: #{params}"

    @cookclass = cookclasses_table.where(id: params[:id]).to_a[0]
    view "new_rsvp"
end

# receive the submitted rsvp form (aka "create")
post "/cookclasses/:id/rsvps/create" do
    puts "params: #{params}"

    # first find the cookclass that rsvp'ing for
    @cookclass = cookclasses_table.where(id: params[:id]).to_a[0]
    # next we want to insert a row in the rsvps table with the rsvp form data
    rsvps_table.insert(
        cookclasses_id: @cookclass[:id],
        user_id: session["user_id"],
        comments: params["comments"],
        going: params["going"]
    )

    redirect "/cookclasses/#{@cookclass[:id]}"
end

# display the rsvp form (aka "edit")
get "/rsvps/:id/edit" do
    puts "params: #{params}"

    @rsvp = rsvps_table.where(id: params["id"]).to_a[0]
    @cookclass = cookclasses_table.where(id: @rsvp[:cookclass_id]).to_a[0]
    view "edit_rsvp"
end

# receive the submitted rsvp form (aka "update")
post "/rsvps/:id/update" do
    puts "params: #{params}"

    # find the rsvp to update
    @rsvp = rsvps_table.where(id: params["id"]).to_a[0]
    # find the rsvp's cookclass
    @cookclass = cookclasses_table.where(id: @rsvp[:cookclass_id]).to_a[0]

    if @current_user && @current_user[:id] == @rsvp[:id]
        rsvps_table.where(id: params["id"]).update(
            going: params["going"],
            comments: params["comments"]
        )

        redirect "/cookclasses/#{@cookclass[:id]}"
    else
        view "error"
    end
end

# delete the rsvp (aka "destroy")
get "/rsvps/:id/destroy" do
    puts "params: #{params}"

    rsvp = rsvps_table.where(id: params["id"]).to_a[0]
    @cookclass = cookclasses_table.where(id: rsvp[:cookclass_id]).to_a[0]

    rsvps_table.where(id: params["id"]).delete

    redirect "/cookclasses/#{@cookclass[:id]}"
end

# display the signup form (aka "new")
get "/users/new" do
    view "new_user"
end

# receive the submitted signup form (aka "create")
post "/users/create" do
    puts "params: #{params}"

    # if there's already a user with this email, skip!
    existing_user = users_table.where(email: params["email"]).to_a[0]
    if existing_user
        view "error"
    else
        users_table.insert(
            name: params["name"],
            email: params["email"],
            password: BCrypt::Password.create(params["password"])
        )

        redirect "/logins/new"
    end
end

# display the login form (aka "new")
get "/logins/new" do
    view "new_login"
end

# receive the submitted login form (aka "create")
post "/logins/create" do
    puts "params: #{params}"

    # step 1: user with the params["email"] ?
    @user = users_table.where(email: params["email"]).to_a[0]

    if @user
        # step 2: if @user, does the encrypted password match?
        if BCrypt::Password.new(@user[:password]) == params["password"]
            # set encrypted cookie for logged in user
            session["user_id"] = @user[:id]
            redirect "/"
        else
            view "create_login_failed"
        end
    else
        view "create_login_failed"
    end
end

# logout user
get "/logout" do
    # remove encrypted cookie for logged out user
    session["user_id"] = nil
    redirect "/logins/new"
end
