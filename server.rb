# server.rb
require 'sinatra'
require 'rethinkdb'
require 'json'
require 'telegram_bot'

include RethinkDB::Shortcuts

get '/getUsers' do
  @listName="Active Users: \n"
  conn=r.connect(:host=>"192.168.38.121", :port=>28015)

  #get active users
  activeUsers=r.db("stf").table("users").pluck("email","name","lastLoggedInAt").filter{ |user| user["lastLoggedInAt"].in_timezone("+07:00").date().eq(r.now().in_timezone("+07:00").date())}.run(conn).to_a
  activeUsers.each do |x|
    @listName+='-'+x['name']+'('+x['email']+")\n"
  end 

  #get new user
  @listName+="\n\n"+"New Users:\n"
  newUsers=r.db("stf").table("users").pluck("email","name","createdAt").filter{ |user| user["createdAt"].in_timezone("+07:00").date().eq(r.now().in_timezone("+07:00").date())}.run(conn).to_a
  newUsers.each do |x|
    @listName+='-'+x['name']+'('+x['email']+")\n"
  end 

  bot = TelegramBot.new(token: '891169911:AAHUaLVENxodctIMvNvbrce6qZIzDaaBtXw')
  channel = TelegramBot::Channel.new(id: -357665531) #-357665531 (Devices farmers), -371604616 warung DF 
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


