#encoding:utf-8
require 'digest/md5'
require 'rc4'
require 'rest-client'
require 'erb'
include ERB::Util




class Auth::BbmallController < ApplicationController


  skip_before_filter :authorize_user!
  layout 'apitest'

  def user_reg 
    rc4_key = '1bb762f7ce24ceee'    
    info_hash={}        
    info_hash[:phone] = params[:ecstore_account][:login_name]
    info_hash = params_info(info_hash) 

    login_name = info_hash[:phone]
    check_user = Ecstore::Account.find_by_login_name(login_name)
    return render :text => '该用户已存在，请登录或用别的手机号码注册' if check_user

    url = 'http://103.16.125.100:9018/user_reg' #生产地址    
    res_data = RestClient.get url, {:params =>info_hash}     
    res_data_hash = ActiveSupport::JSON.decode(res_data)

    if res_data_hash['code'] == 0
      pw_enc = res_data_hash['data']['password']
      uid = res_data_hash['data']['uid']
      password = de_code(pw_enc)
      msg_send = "#{password}: #{uid}"
      #return render :text => msg_send
      
      expires_in = 7200
      auth_ext = Ecstore::AuthExt.where(:provider=>"51bbmall",
        :uid=>uid).first_or_initialize(
        :expires_at=>expires_in + Time.now.to_i,
        :expires_in=>expires_in)        

        if res_data_hash['data']['first'] == '1'
          msg_send =  url_encode("注册成功！您的初始密码是：") + password + url_encode("，您的用户id是：") + uid + url_encode("。")
          send_sms(info_hash[:phone], msg_send) # send password to user
          redirect_to api_login_path
        else render :text => '该手机号码已被注册'
        end
      else
        message = '错误代码=' + res_data_hash['code'].to_s + ":  #{res_data_hash['msg']}"
        flash.now[:alert] = "#{message}"
        return render :text=>message
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
          #return render :text => '您已登陆！'
        end   
      end        


      login_url = 'http://103.16.125.100:9018/user_login'      
      info_hash={}        
      info_hash[:account] = params[:ecstore_account][:login_name]
      password = params[:ecstore_account][:password]
      info_hash[:password] = Digest::MD5.hexdigest(password)
      info_hash = params_info(info_hash)

      res_data = RestClient.get login_url, {:params => info_hash}          
      res_data_hash = ActiveSupport::JSON.decode(res_data)         

      if res_data_hash['code'] == 0
        if Ecstore::Account.find_by_login_name(info_hash[:account]).nil?
          now = Time.now
          @account = Ecstore::Account.new do |ac|
            ac.login_name = info_hash[:account]
            ac.login_password = '123456'
            ac.account_type ="member"
            ac.createtime = now.to_i
            ac.auth_ext = auth_ext
          end

          Ecstore::Account.transaction do
            if @account.save!(:validate => false)
              @user = Ecstore::User.new do |u|
                u.member_id = @account.account_id
                u.mobile = @account.login_name
                u.source = "51bbmall"
                u.member_lv_id = 1
                u.cur = "CNY"
                u.reg_ip = request.remote_ip  
                u.regtime = now.to_i
                u.email = "#{@account.login_name}@qq.com"
              end
              @user.save!(:validate=>false)
            end
          end
        end
        account = Ecstore::Account.find_by_login_name(info_hash[:account])
        sign_in(account, '1')
        flash[:success] = '登录成功！'
        redirect_to '/'
      else
        message = res_data_hash['code'].to_s + ":#{res_data_hash['msg']}"
        flash.now[:danger] = "#{message}"
        return render :text => message
      end
    end


    def send_sms(phone, message)        
      send_sms_url = 'http://103.16.125.100:9018/send_sms' 
      info_hash = {}       
      info_hash[:phone] = phone
      info_hash = params_info(info_hash)        
      info_hash[:content] = message        

      res_data = RestClient.get send_sms_url, {:params => info_hash}
      res_data_hash = ActiveSupport::JSON.decode res_data

      if res_data_hash['code'] == 0
        flash[:success] = '信息发送成功！'
      else
        message_error = "发送失败，错误：#{res_data_hash['msg']}"
      end
    end


    def user_info
      user_info_url = 'http://103.16.125.100:9018/user_info'
      info_hash = {}
      #info_hash[:account] = params[:ecstore_account][:login_name]
      info_hash[:account] = '13501725689'
      info_hash = params_info(info_hash)

      res_data = RestClient.get user_info_url, {:params => info_hash}
      res_data_hash = ActiveSupport::JSON.decode res_data
      info_hash[:phone] = info_hash[:account]

      if res_data_hash['code'] == 0
        res_data_hash['data']['password'] = de_code(res_data_hash['data']['password'])
        render :text => res_data_hash['data']
      else
        return render :text => message_error = "错误：#{res_data_hash['msg']}"
      end
    end

    def change_pwd
      change_pwd_url = 'http://103.16.125.100:9018/change_pwd'
      info_hash = {}
      info_hash[:uid] = params[:ecstore_account][:login_name].auth_ext.uid
      info_hash = params_info(info_hash)
      info_hash[:old_pwd] = params[:ecstore_account][:old_pwd]
      info_hash[:new_pwd] = params[:ecstore_account][:new_pwd]
      res_data = RestClient.get user_info_url, {:params => info_hash}
      res_data_hash = ActiveSupport::JSON.decode res_data

      if res_data_hash['code'] == 0
        render :text => res_data_hash['msg']
      else
        render :text => message_error = "错误：#{res_data_hash['msg']}"
      end
    end

    def change_phone
      change_pwd_url = 'http://103.16.125.100:9018/change_phone'
      info_hash = {}
      uid = info_hash[:uid] = params[:ecstore_account][:login_name].auth_ext.uid
      phone = info_hash[:phone] = params[:ecstore_account][:login_name]
      info_hash = params_info(info_hash)
      info_hash[:password] = Digest::MD5.hexdigest params[:ecstore_account][:password]
      info_hash[:type] = 1
      res_data = RestClient.get user_info_url, {:params => info_hash}
      res_data_hash = ActiveSupport::JSON.decode res_data

      if res_data_hash['code'] == 0
        #redirect_to 提交验证码页面
        info_hash = {}
        info_hash[:uid] = uid
        info_hash[:phone] = phone
        info_hash = params_info(info_hash)
        info_hash[:sms_code] = params[:sms_code]
        info_hash[:type] = 2
        res_data = RestClient.get user_info_url, {:params => info_hash}
        res_data_hash = ActiveSupport::JSON.decode res_data

        if res_data_hash['code'] == 0
          render :text => res_data_hash['msg']
        else
          render :text => message_error = "错误：#{res_data_hash['msg']}"
        end
      else
        render :text => message_error = "错误：#{res_data_hash['msg']}"
      end
    end




    



    private

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

    def hex2asc(str)
      arr = []
      (0..str.length - 2).step(2) do |x|
        arr << str.slice(x, 2).hex.chr
      end
      arr.join
    end


    def de_code(password)
      de_password = hex2asc(password)      
      rc4_key = '1bb762f7ce24ceee'
      dec=RC4.new(rc4_key)
      password = dec.decrypt(de_password)
    end
  end
