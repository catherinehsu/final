# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model

DB.create_table! :cookclasses do
  primary_key :id
  String :title
  String :description, text: true
  String :when
  String :location
end
DB.create_table! :rsvps do
  primary_key :id
  foreign_key :cookclasses_id
  Boolean :going
  String :name
  String :email
  String :comments, text: true
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end

# Insert initial (seed) data
cookclasses_table = DB.from(:cookclasses)

cookclasses_table.insert(title: "Oodles of Noodles", 
                    description: "Taiwanese Beef Noodle Soup | Tomato Noodle Soup",
                    when: "March 14, 6:00 PM (PST)")

cookclasses_table.insert(title: "Eggcelent Dishes", 
                    description: "Chinese Tomato and Egg dish | Custard Egg Tarts",
                    when: "March 21, Noon (PST)")

cookclasses_table.insert(title: "No Meat meet-up", 
                    description: "Stir-fried Chinese Eggplant | Ma-po Tofu",
                    when: "March 28, 6:00 PM (PST)")
puts "Success!"