#encoding:utf-8
class HomeController < ApplicationController
  before_filter :find_user
	# layout 'magazine'
	layout 'standard'

	def index

		@title = "邦邦芒商城"
		#@home = Ecstore::Home.last
		if signed_in?
		   redirect_to params[:return_url] if params[:return_url].present?
		end
	end

	def floor
		@id = params[:id]
		@home = Ecstore::Home.last
		render :layout=>'blank'
	end

	def index1

		@title = "邦邦芒商城"
		@home = Ecstore::Home.last
		if signed_in?
		   redirect_to params[:return_url] if params[:return_url].present?
		end
		@big_save = recommend_goods('Big Save')
		@special =  recommend_goods('Special')
		@suppliers_goods = recommend_goods('Suppliers Goods')
		@top_review = recommend_goods('Top Review')
		

		@latest_goods = Ecstore::Good.where(:marketable =>'true').order("p_order ASC, goods_id DESC").limit(4)
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

	private
		def recommend_goods(recommend_name)

	        goods_ids =""
	        sql = "select replace(replace(replace(field_vals,'---\n- ',''''),'- ',','''),'\n','''') as goods_ids FROM mdk.sdb_imodec_promotions where name='#{recommend_name}'"
	        results = ActiveRecord::Base.connection.execute(sql)
	        results.each(:as => :hash) do |row|
	            goods_ids= row["goods_ids"]
	        end
	        if goods_ids.size>0
	           sql = "marketable='true' and bn in (#{goods_ids})"
	           Ecstore::Good.where(sql)
	        end

		end

end
