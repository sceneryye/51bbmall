#encoding:utf-8
class Admin::BaseController < ActionController::Base
	include Admin::SessionsHelper

	protect_from_forgery

	layout 'admin'
	require "pp"

	

#	before_filter :authorize_admin!
#	before_filter :require_permission!,:except=>[:select_goods,:select_gifts,:select_coupons,:search]

	def authorize_admin!
		redirect_to new_admin_session_path unless current_admin
	end

	def require_permission!
		return true if controller_name == "sessions"
		unless current_admin.has_right_of(controller_name,action_name)
			if request.xhr?
				render :js=>"alert('您没有权限操作！')"
			else
				render :text=>"您没有权限操作！",:layout=>"admin"
			end
		end
		
	end


	def water_logger
		Logger.new("log/watermark.log")
	end

	def coupon_logger
		@logger ||= Logger.new("log/coupon.log")
	end

	def params_info(options={})
    brand_id = 'bb'
    client_id = 'bbzg'
    phone = params[:phone]
    key = '1ed97bd965a8f052'
    rc4_key = '1bb762f7ce24ceee'
    ts = Time.now.to_i

    info_hash={}    
    info_hash[:brand_id] = brand_id
    info_hash[:client_id] = client_id
    info_hash.merge! options
    info_hash[:ts] = ts.to_s

    unsign = info_hash.map {|key,val| "#{val}"}.join('') + key
    info_hash[:sign]  = Digest::MD5.hexdigest(unsign)
    info_hash
  end

  def user_wallet
    user_wallet_url = 'http://103.16.125.100:9018/user_wallet'
    info_hash = {}
    uid = info_hash[:uid] = current_user.uid      
    info_hash = params_info(info_hash)      
    res_data = RestClient.get user_wallet_url, {:params => info_hash}
    res_data_hash = ActiveSupport::JSON.decode res_data

    if res_data_hash['code'] == 0
      return res_data_hash['data']['balance']
    else
      render :text => message_error = "错误：#{res_data_hash['msg']}"
    end
  end

  def user_wallet(uid = current_user.uid)
    user_wallet_url = 'http://103.16.125.100:9018/user_wallet'
    info_hash = {}
    info_hash[:uid] = uid      
    info_hash = params_info(info_hash)      
    res_data = RestClient.get user_wallet_url, {:params => info_hash}
    res_data_hash = ActiveSupport::JSON.decode res_data

    if res_data_hash['code'] == 0
      return res_data_hash['data']['balance']
    else
      render :text => message_error = "错误：#{res_data_hash['msg']}"
    end
  end

  def user_charge(uid, money, acct_type, valid_month, remark)
    user_charge_url = 'http://103.16.125.100:9018/user_charge'
    info_hash = {}
    info_hash[:uid] = uid
    info_hash[:money] = money    
    info_hash = params_info(info_hash)
    info_hash[:order_no] = '23' + rand(10).to_s.rjust(2, '0') + 
    Time.now.strftime('%Y%m%d%H%M%S') + rand(10).to_s.rjust(4, '0') + uid 
    info_hash[:acct_type] = acct_type
    info_hash[:valid_month] = valid_month   
    info_hash[:remark] = url_encode remark

    res_data = RestClient.get user_charge_url, {:params => info_hash}
    res_data_hash = ActiveSupport::JSON.decode res_data

    res_data_hash
  end



end


