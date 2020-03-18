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
  String :price
  String :longdescription, text: true
  String :instructor
end
DB.create_table! :rsvps do
  primary_key :id
  foreign_key :cookclass_id
  foreign_key :user_id
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
                    when: "March 14, 6:00 PM (PST)",
                    location: "4853 Main St, Vancouver, BC V5V 3R9",
                    price: "$70",
                    instructor: "David Chang",
                    longdescription: "What better way to beat the cold weather than to warm up with a hearty bowl of noodle soup! This class features two Taiwanese classics that will be your go-to during the winter season. Learn how to make two delicious broths from scratch, which will infuse your noodles with oodles of flavour.")

cookclasses_table.insert(title: "Eggcelent Dishes", 
                    description: "Chinese Tomato and Egg dish | Custard Egg Tarts",
                    when: "March 21, Noon (PST)",
                    location: "1598 E Hastings St, Vancouver, BC V5L 1S5",
                    price: "$40",
                    instructor: "Gordon Ramsay",
                    longdescription: "This class is inspired by my father's love for all things egg! Start off with a simple yet classic dish, and finish off with a dim-sum dessert favorite!")

cookclasses_table.insert(title: "No Meat meet-up", 
                    description: "Stir-fried Chinese Eggplant | Ma-po Tofu",
                    when: "March 28, 6:00 PM (PST)",
                    location: "3995 Main St, Vancouver, BC V5V 3P3",
                    price: "$60",
                    instructor: "Sanne Vloet",
                    longdescription: "Vegetarians unite! In this class, you'll learn Chinese stir-fry basics that'll open your bellies up to a new world of hot veggie dishes")
puts "Success!"