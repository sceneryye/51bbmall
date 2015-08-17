#encoding:utf-8
require 'digest/md5'
require 'rc4'
require 'rest-client'




class Auth::BbmallController < ApplicationController


  skip_before_filter :authorize_user!

  def user_reg 
    #phone = params[:phone]
    phone = '15800694393' 
    key = '2c31b08f6a79f06f'
    rc4_key = '1bb762f7ce24ceee'
    ts = Time.now.to_i
    info_hash={}        
    info_hash[:phone] = params[:login_name]
    info_hash = params_info(info_hash) 


    url = 'http://103.16.125.100:9018/user_reg' #生产地址
    
    res_data = RestClient.get url, {:params =>info_hash}    
    
    res_data_hash = ActiveSupport::JSON.decode(res_data)

    if res_data_hash['code']=='0'
      enc=RC4.new(rc4_key)
      password = enc.encrypt(res_data_hash['password'])
      uid = res_data_hash['data']['uid']
      pw_enc = res_data_hash['data']['password']
      expires_in = 7200

      auth_ext = Ecstore::AuthExt.where(:provider=>"51bbmall",
        :uid=>uid).first_or_initialize(
        :expires_at=>expires_in + Time.now.to_i,
        :expires_in=>expires_in)

        login_name = phone
        check_user = Ecstore::Account.find_by_login_name(login_name)

        return redirect_to '/' if check_user

        now = Time.now
        @account = Ecstore::Account.new do |ac|
          ac.login_name = login_name
          ac.login_password = '123456'
          ac.account_type ="member"
          ac.createtime = now.to_i
          ac.auth_ext = auth_ext
        end

        Ecstore::Account.transaction do
          if @account.save!(:validate => false)
            @user = Ecstore::User.new do |u|
              u.member_id = @account.account_id
              u.mobile = phone
              u.source = "email139"
              u.member_lv_id = 1
              u.cur = "CNY"
              u.reg_ip = request.remote_ip  
              u.regtime = now.to_i
            end
            @user.save!(:validate=>false)
            sign_in(@account,'1')
          end
        end
        msg_sent = "欢迎注册！您的密码为#{password}, 用户id为#{res_data_hash['uid']}, 请尽快更改密码。"
          sms_sent(phone, msg_sent) # sent password to user
        else
          message = '错误代码=' + res_data_hash['code'].to_s + ":  #{res_data_hash['msg']}"
          flash.now[:alert] = "#{message}"
          #return render :text=>message
        end 
      end


      def user_login
        auth_ext = Ecstore::AuthExt.find_by_id(cookies.signed[:_auth_ext].to_i) if cookies.signed[:_auth_ext]
        session[:from] = "external_auth"

        if auth_ext&&!auth_ext.expired?&&auth_ext.provider == '51bbmall'
          if auth_ext.account.nil?
            cookies.delete :_auth_ext   
          else
            sign_in(auth_ext.account)
            return redirect_to "/mobile/#{shop_id}/shop"
          end   
        end

        
        
        rc4_key = '1bb762f7ce24ceee'        
        login_url = 'http://103.16.125.100:9018/user_login'

        info_hash={}        
        info_hash[:account] = params[:account]
        info_hash[:password] = Digest::Md5.hexdigest(params[:password])
        info_hash = params_info(info_hash)              
        
        res_data = RestClient.post url, info_hash          
        res_data_hash = ActiveSupport::JSON.decode(res_data)         

        if res_data_hash[:code] == 0
          sign_in(info_hash[:account])
          return redirect_to '/'
        else
          message = res_data_hash['code'] + ":#{res_data_hash['msg']}"
          return render :text=>message
        end
      end


      def sent_sms(phone, message)        
        sent_sms_url = 'http://103.16.125.100:9018/send_sms' 
        info_hash = {}       
        info_hash[:phone] = phone
        info_hash = params_info(info_hash)        
        info_hash[:content] = message        

        res_data = RestClient get sms_sent_url, {:params => info_hash}
        res_data_hash = ActiveSupport::JSON.decode res_data

        if res_data_hash['code'] == '0'
          flash[:success] = '信息发送成功！'
        else
          message = "发送失败，错误代码：#{res_data_hash['msg']}"
        end
      end


      def cancel
      end


      private

      def params_info(options={})
        brand_id = 'itd'
        client_id = 'itd'
        phone = params[:phone]
        key = '2c31b08f6a79f06f'
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
end
