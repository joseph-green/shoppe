require 'spec_helper'

describe "EcommerceStore" do 
	"/get" do
		it "should load the store" do
			expect("/get").to be_ok
		end
	end
	
end