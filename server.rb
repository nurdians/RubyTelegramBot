# server.rb
require 'sinatra'
require 'rethinkdb'
require 'json'
require 'telegram_bot'

include RethinkDB::Shortcuts

get '/getUsers' do
  @listName="Active Users: \n"
  conn=r.connect(:host=>"192.168.38.121", :port=>28015)
  userLists=Array.new

  #get active users base on login date
  activeUsers=r.db("stf").table("users").pluck("email","lastLoggedInAt").filter{ |doc| doc["lastLoggedInAt"].in_timezone("+07:00").date().eq(r.now().in_timezone("+07:00").date())}.run(conn).to_a
  activeUsers.each do |x|
    userLists.push(x['email'])
  end 

  #get active users base on log
  activeUsersBaseOnLog=r.db('stf').table('logs').pluck('message','timestamp').filter{ |doc| doc['message'].match("^Now owned by ")}.filter{ |doc| doc["timestamp"].in_timezone("+07:00").date().eq(r.now().in_timezone("+07:00").date())}.run(conn).to_a
  activeUsersBaseOnLog.each do |x|
    userLists.push(x['message'].sub("Now owned by \"","").sub("\"",""))
  end 

  activeUsersAll=r.db("stf").table("users").pluck("email","name").filter{ |doc| r.expr(userLists).contains(doc["email"])}.run(conn).to_a
  activeUsersAll.each do |x|
    @listName+='-'+x['name']+'('+x['email']+")\n"
  end 
 
  #get new user
  @listName+="\n\n"+"New Users:\n"
  newUsers=r.db("stf").table("users").pluck("email","name","createdAt").filter{ |user| user["createdAt"].in_timezone("+07:00").date().eq(r.now().in_timezone("+07:00").date())}.run(conn).to_a
  newUsers.each do |x|
    @listName+='-'+x['name']+'('+x['email']+")\n"
  end 

  bot = TelegramBot.new(token: '894058393:AAEPHq0MW6FXUWC5sNWIJsTNBP9uNPlZbic')
  channel = TelegramBot::Channel.new(id: -357665531) #-357665531 (Devices farmers), -371604616 warung DF, 591524801 private
  message = TelegramBot::OutMessage.new
  message.chat = channel
  message.text = @listName
  message.send_with(bot)

  #puts @listName
  conn.close
  #Ffor json output
  #content_type :json
  #a.to_json
end


