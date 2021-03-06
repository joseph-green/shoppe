require 'sinatra'
require 'sinatra/cookies'
require 'sinatra/reloader'
require 'sinatra/namespace'
require 'data_mapper'
require 'stripe'
require 'dm-timestamps'



enable :sessions
DataMapper.setup(:default,"sqlite://#{Dir.pwd}/items.db")

class Item
	include DataMapper::Resource

	property :id, Serial
	property :name, String
	property :product_description, String
	property :price, Numeric
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
	erb :new
end

post '/new' do
	#checks if admin
	#creates product
	halt 401 unless session[:admin]
	@item = Item.new(
		:name=>params['name'],
		:price=>params['price'].to_i,
		:created_at=>Time.now,
		:product_description=>params['description'])
	@item.save
	redirect to("/")
		
end





get '/:product_id/edit' do |id|
	#checks admin
	#displays form to edit existing product
	#sends POST request after "submit" is clicked
	halt 401 unless session[:admin]
	#check to see if the item exists in the database
	begin
		@item = Item.get(id.to_i)
	rescue ObjectNotFoundError
		redirect to("/404?error=Item+Not+Found")
	end
	#loads the erb template
	
	erb :update



end 

post '/:product_id/edit' do |id|
	#checks admin
	#updates information in the database
	halt 401 unless session[:admin]
	#check to see if the item exists in the database
	begin
		@item = Item.get(id.to_i)
	rescue ObjectNotFoundError
		redirect to("/404?error=Item+Not+Found")
	end
	#updates the record
	#there should be a more finesse way to update only one attribute at time
	@item.update(
		:name=>params['name'],
		:price=>params['price'].to_i,
		:product_description=>params['description'])
	redirect to("/")

end

get '/:product_id/delete' do |id|
	#checks admin
	halt 401 unless session[:admin]
	
	erb :delete
	
	
end 

post '/:product_id/delete' do |id|
	
	#checks admin
	halt 401 unless session[:admin]
	#verifies whether you want the product to be deleted
	begin
		@item = Item.get(id.to_i)
	rescue ObjectNotFoundError
		redirect to("/404?error=Item+Not+Found")
	end
	@item.destroy

end




get '/:product_id/buy' do |id|
	#actually buying the product
	#loads purchasing page (erb), which is form to insert purchasing info
	
		@item = Item.get(id.to_i)
		erb :buy
	


end

post '/:product_id/buy' do |id|
	@item = Item.get(id.to_i)
	
	Stripe.api_key = "sk_test_2xbQJY3bGbYtvZpgQbLkhdYW"

	
	token = params[:stripeToken]
	begin

	
		charge = Stripe::Charge.create(
	    :amount => @item.price.to_i * 100, 
	    :currency => "cad",
	    :source => token,
	    :description => @item.name
	  )
	rescue Stripe::CardError => e
	 
	  body = e.json_body
	  err  = body[:error]

	  puts "Status is: #{e.http_status}"
	  puts "Type is: #{err[:type]}"
	  puts "Code is: #{err[:code]}"
	  
	  puts "Param is: #{err[:param]}"
	  puts "Message is: #{err[:message]}"

	rescue Stripe::RateLimitError => e
	 
	rescue Stripe::InvalidRequestError => e
	 
	rescue Stripe::AuthenticationError => e

	rescue Stripe::APIConnectionError => e

	rescue Stripe::StripeError => e

	rescue => e

	end

	redirect to("/")
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
		erb :login


	end

	post '/login' do
		begin
			@admin = Admin.all(:username => params['username'])[0]

		rescue
			redirect to('/login?error=username'), "Sorry, we couldn't find an admin with that username"
		end
		redirect to('/login?error=password') unless @admin.password == params['password']
		session[:admin] = true
		redirect to('/')
	end

	get '/new' do

		#halt 401 unless session[:admin]

		erb :new_admin

	end

	post '/new' do

		halt 401 unless session[:admin]
		
		@admin = Admin.new(
			:username => params['username'],
			:password => params['password'])
		
		@admin.save
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
