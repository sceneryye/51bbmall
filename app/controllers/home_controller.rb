#encoding:utf-8
class HomeController < ApplicationController
  before_filter :find_user
	# layout 'magazine'
	layout 'standard'

	def index

		@title = "邦邦芒商城"
		@home = Ecstore::Home.last
		if signed_in?
		   redirect_to params[:return_url] if params[:return_url].present?
		end
	end

	def index1

		@title = "邦邦芒商城"
		@home = Ecstore::Home.last
		if signed_in?
		   redirect_to params[:return_url] if params[:return_url].present?
		end
	end

	def blank
		@return_url = params[:return_url]
		render :layout=>nil
	end

	def topmenu
		render :layout=>nil
	end
	
	def subscription_success
		@title = "邦邦芒商城"
	end

end
