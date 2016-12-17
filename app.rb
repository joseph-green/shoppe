require 'sinatra'
require 'sinatra/cookies'
require 'sinatra/reloader'
require 'sinatra/namespace'
require 'data_mapper'
require 'stripe'
require 'dm-timestamps'



enable :sessions
DataMapper.setup(:default,"sqlite://#{Dir.pwd}/database.db")

class Item
	include DataMapper::Resource

	property :id, Serial
	property :name, String
	property :product_description, String
	property :price, Decimal
	property :created_at, DateTime
	
	

end

class Admin
	include DataMapper::Resource

	property :id, Serial
	property :username, String
	property :password, String

end

DataMapper.finalize.auto_upgrade!

get '/' do
	#display the site
	#index of all products
	@items = Item.all
	
	#loads the erb
	erb :root
end

get '/new' do
	#checks admin
	#displays form to create new product
	#sends POST request after "submit" is clicked
	halt 401 unless session[:admin]
	#loads the erb
end

post '/new' do
	#checks if admin
	#creates product
	halt 401 unless session[:admin]
	@item = Item.new(
		:name=>params['name'],
		:price=>params['price'].to_f,
		:created_at=>Time.now,
		:product_description=>params['description'])
	@item.save
		
end





get '/:product_id/update' do |id|
	#checks admin
	#displays form to edit existing product
	#sends POST request after "submit" is clicked
	halt 401 unless session[:admin]
	#check to see if the item exists in the database
	begin
		@item = Item.get!(:id => id)
	rescue ObjectNotFoundError
		redirect to("/404?error=Item+Not+Found")
	end
	#loads the erb template



end 

post '/:product_id/update' do |id|
	#checks admin
	#updates information in the database
	halt 401 unless session[:admin]
	#check to see if the item exists in the database
	begin
		@item = Item.get!(:id => id)
	rescue ObjectNotFoundError
		redirect to("/404?error=Item+Not+Found")
	end
	#updates the record
	#there should be a more finesse way to update only one attribute at time
	@item = Item.update(
		:name=>params['name'],
		:price=>params['price'].to_f,
		:product_description=>params['description'])

end

get '/:product_id/delete' do |id|
	#checks admin
	halt 401 unless session[:admin]
	#verifies whether you want the product to be deleted
	begin
		@item = Item.get!(:id => id)
	rescue ObjectNotFoundError
		redirect to("/404?error=Item+Not+Found")
	end
	
end 

post '/:product_id/delete' do |id|
	#checks admin
	halt 401 unless session[:admin]

end




get '/:product_id/buy' do |id|
	#actually buying the product
	#loads purchasing page (erb), which is form to insert purchasing info
	begin
		@item = Item.get!(:id => id)
	rescue
		redirect to("/404?error=Item+Not+Found")
	end


end

post '/:product_id/buy' do |id|
	#actually buying the product
	#sends information collected in the GET page and sends it through the Stripe API

end

get '/404' do
	p params['error']
end




namespace '/admin' do
	get '/login' do
		#admin login
		#loads form
		#send POST request to "/login" when clicked

		#loads the erb


	end

	post '/login' do
		begin
			@admin = Admin.find(:username => params['username'])

		rescue
			redirect to('/login?error=username'), "Sorry, we couldn't find an admin with that username"
		end
		redirect to('/login?error=password') unless @admin.password = params['password']
		session[:admin] = true
		redirect to('/')
	end
end

=begin

#Stripe's error handling

begin
  # Use Stripe's library to make requests...
rescue Stripe::CardError => e
  # Since it's a decline, Stripe::CardError will be caught
  body = e.json_body
  err  = body[:error]

  puts "Status is: #{e.http_status}"
  puts "Type is: #{err[:type]}"
  puts "Code is: #{err[:code]}"
  # param is '' in this case
  puts "Param is: #{err[:param]}"
  puts "Message is: #{err[:message]}"
rescue Stripe::RateLimitError => e
  # Too many requests made to the API too quickly
rescue Stripe::InvalidRequestError => e
  # Invalid parameters were supplied to Stripe's API
rescue Stripe::AuthenticationError => e
  # Authentication with Stripe's API failed
  # (maybe you changed API keys recently)
rescue Stripe::APIConnectionError => e
  # Network communication with Stripe failed
rescue Stripe::StripeError => e
  # Display a very generic error to the user, and maybe send
  # yourself an email
rescue => e
  # Something else happened, completely unrelated to Stripe
end
	
=end
