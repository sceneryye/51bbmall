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
          session.delete(:send_sms_msg)
          flash[:success] = '注册成功，请查看手机短信！'
          redirect_to api_login_path
        else
          flash[:alert] = "该手机号已经被注册！"
          redirect_to login_path
        end
      else
        message = '错误代码=' + res_data_hash['code'].to_s + ":  #{res_data_hash['msg']}"
        flash[:alert] = "#{message}"
        redirect_to login_path
      end
    end




    def user_login login_name = nil, passowrd = nil

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
      info_hash[:account] = login_name || params[:ecstore_account][:login_name]
      password = password || params[:ecstore_account][:password]
      info_hash[:password] = Digest::MD5.hexdigest(password)
      info_hash = params_info(info_hash)

      res_data = RestClient.get login_url, {:params => info_hash}
      res_data_hash = ActiveSupport::JSON.decode(res_data)

      expires_in = 7200
      if res_data_hash['code'] == 0
        if Ecstore::Account.find_by_login_name(info_hash[:account]).nil?
          now = Time.now
          @account = Ecstore::Account.new do |ac|
            ac.login_name = info_hash[:account]
            ac.login_password = '123456'
            ac.account_type ="member"
            ac.createtime = now.to_i
            ac.auth_ext = auth_ext
            ac.uid = res_data_hash['data']['uid']
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
        @message = res_data_hash['code'].to_s + ":#{res_data_hash['msg']}"
        redirect_to login_path
        flash[:danger] = "#{@message}"
      end
    end


    def send_sms(phone, message)
      send_sms_url = 'http://103.16.125.100:9018/send_sms'
      info_hash = {}
      info_hash[:phone] = phone
      info_hash = params_info(info_hash)
      info_hash[:content] = message

      res_data = RestClient.get send_sms_url, {:params => info_hash}
      session[:send_sms_msg] = res_data_hash = ActiveSupport::JSON.decode res_data

      if res_data_hash['code'] == 0
        return res_data_hash
      else
        message_error = "发送失败，错误：#{res_data_hash['msg']}"
      end
    end


    def user_info uid = nil
      user_info_url = 'http://103.16.125.100:9018/user_info'
      info_hash = {}
      info_hash[:account] = uid || current_user.login_name
      info_hash = params_info(info_hash)

      res_data = RestClient.get user_info_url, {:params => info_hash}
      res_data_hash = ActiveSupport::JSON.decode res_data

      if res_data_hash['code'] == 0
        res_data_hash['data']['password'] = de_code(res_data_hash['data']['password'])
      end
      res_data_hash
    end

    def change_pwd
      change_pwd_url = 'http://103.16.125.100:9018/change_pwd'
      info_hash = {}
      info_hash[:uid] = current_user.uid
      info_hash = params_info(info_hash)
      info_hash[:old_pwd] = en_code params[:ecstore_account][:old_pwd]
      info_hash[:new_pwd] = en_code params[:ecstore_account][:new_pwd]
      res_data = RestClient.get change_pwd_url, {:params => info_hash}
      res_data_hash = ActiveSupport::JSON.decode res_data

      if res_data_hash['code'] == 0
        render :text => '密码修改成功！'
      else
        render :text => message_error = "错误#{res_data_hash['code']}：#{res_data_hash['msg']}"
      end
    end

    def change_phone
      change_phone_url = 'http://103.16.125.100:9018/change_phone'
      info_hash = {}
      uid = info_hash[:uid] = current_user.uid
      session[:phone] = phone = info_hash[:phone] = params[:ecstore_account][:login_name]
      info_hash = params_info(info_hash)
      info_hash[:password] = Digest::MD5.hexdigest params[:ecstore_account][:password]
      info_hash[:type] = 1
      res_data = RestClient.get change_phone_url, {:params => info_hash}
      res_data_hash = ActiveSupport::JSON.decode res_data

      if res_data_hash['code'] == 0
        redirect_to api_validate_code_path
      else
        render :text => message_error = "错误：#{res_data_hash['msg']}"
      end
    end

    def validate_code
      change_phone_url = 'http://103.16.125.100:9018/change_phone'
      info_hash = {}
      uid = info_hash[:uid] = current_user.uid
      info_hash[:phone] = session[:phone]

      session.delete(:phone)
      info_hash = params_info(info_hash)
      info_hash[:sms_code] = params[:ecstore_account][:account_type]
      info_hash[:type] = 2
      return render :text => info_hash
      res_data = RestClient.get change_phone_url, {:params => info_hash}
      res_data_hash = ActiveSupport::JSON.decode res_data

      if res_data_hash['code'] == 0
        current_user.update_attribute!(:login_name, info_hash[:phone])
        current_user.user.update_attribute!(:mobile, info_hash[:phone])
        render :text => "重新绑定手机成功！您现在的绑定手机为：#{current_user.login_name}"
      else
        render :text => message_error = "错误：#{res_data_hash['msg']}"
      end
    end




    def user_charge
      user_charge_url = 'http://103.16.125.100:9018/user_charge'
      info_hash = {}
      uid = info_hash[:uid] = current_user.uid
      info_hash[:money] = params[:money].to_i
      info_hash = params_info(info_hash)
      info_hash[:order_no] = '23' + rand(10).to_s.rjust(2, '0') +
      Time.now.strftime('%Y%m%d%H%M%S') + rand(10).to_s.rjust(4, '0') + current_user.uid
      info_hash[:acct_type] = params[:acct_type].to_i
      info_hash[:valid_month] = params[:valid_month].to_i
      info_hash[:remark] = url_encode params[:remark]
      res_data = RestClient.get user_charge_url, {:params => info_hash}
      res_data_hash = ActiveSupport::JSON.decode res_data

      if res_data_hash['code'] == 0
        render :text => res_data_hash
      else
        render :text => message_error = "错误：#{res_data_hash['msg']}"
      end
    end


    def user_deduct
      balance = user_wallet
      user_deduct_url = 'http://103.16.125.100:9018/user_deduct'
      info_hash = {}
      uid = info_hash[:uid] = current_user.uid
      info_hash[:money] = params[:money].to_i
      if info_hash[:money] <= balance.to_i
        info_hash = params_info(info_hash)
        info_hash[:acct_type] = params[:acct_type].to_i
        info_hash[:order_no] = '23' + rand(10).to_s.rjust(2, '0') +
        Time.now.strftime('%Y%m%d%H%M%S') + rand(10).to_s.rjust(4, '0') + current_user.uid
        info_hash[:remark] = url_encode params[:remark]
        #return render :text => info_hash
        res_data = RestClient.get user_deduct_url, {:params => info_hash}
        res_data_hash = ActiveSupport::JSON.decode res_data
        if res_data_hash['code'] == 0
          render :text => res_data_hash
        else
          render :text => message_error = "#{res_data_hash['code']}：#{res_data_hash['msg']}"
        end
      else
        render :text => "您的余额不足，当前余额为:#{balance}"
      end
    end


    def card_pay
      card_pay_url = 'http://103.16.125.100:9018/card_pay'
      info_hash = {}
      uid = info_hash[:uid] = current_user.uid
      info_hash[:card_password] = params[:card_password]
      info_hash = params_info(info_hash)
      info_hash[:card_no] = params[:card_no]
      res_data = RestClient.get card_pay_url, {:params => info_hash}
      res_data_hash = ActiveSupport::JSON.decode res_data

      if res_data_hash['code'] == 0
        render :text => res_data_hash
      else
        render :text => message_error = "错误：#{res_data_hash['msg']}"
      end
    end


    def forget_pwd_step1
      cookies[:login_name] = params[:login_name]
      cookies[:code] = rand(100_000).to_s.rjust(6, '0')
      msg_send = url_encode('您的验证码是：') + cookies[:code] + url_encode('，如非您本人操作，请忽略该短信。')
      send_sms(cookies[:login_name], msg_send)
      if session[:send_sms_msg]['code'] == 0
        redirect_to api_forget_pwd_step2_path
      else
        render :text => session[:send_sms_msg]['msg']
      end
      session.delete(:send_sms_msg)
    end


    def forget_pwd_step2
      if params[:validate_code] == cookies[:code]
        info_hash = {}
        info_hash[:account] = cookies[:login_name]
        info_hash = params_info info_hash
        url = 'http://103.16.125.100:9018/user_info' #生产地址
        res_data = RestClient.get url, {:params =>info_hash}
        res_data_hash = ActiveSupport::JSON.decode(res_data)
        cookies.delete(:login_name)
        cookies.delete(:code)

        if res_data_hash['code'] == 0
          pw_enc = res_data_hash['data']['password']
          password = de_code(pw_enc)
          msg_send =  url_encode("您的密码是：") + password + url_encode("，请妥善保存或立即修改密码。")
          send_sms(info_hash[:account], msg_send) # send password to user
          session.delete(:send_sms_msg)
          if res_data_hash['code'] == 0
            redirect_to login_path
          else
            render :text => res_data_hash['msg']
          end
        else
          message = '错误代码=' + res_data_hash['code'].to_s + ":  #{res_data_hash['msg']}"
          flash.now[:alert] = "#{message}"
          return render :text=>message
        end

      else
        render :text => '验证码不正确！'
      end
    end

    def send_validate_code
      phone = params['phone']
      @code = rand(100000).to_s.rjust(6, '0')
      msg = url_encode("您的验证码为：") + @code + url_encode(",若非本人操作，请忽略该信息。")
      send_sms phone, msg
    end

    def synchro_login
      a_id = '0'
      app_id = '1001'
      serve = 'user.login'
      ts = Time.now.to_i.to_s
      uid = params[:uid]
      ks = "a_id=0&appid=1001&cs=app&service=user.login&timestamp=" + ts + "&u_id=" + uid+ "&key=abcdefghijkLMNOPQ"
      key_string = Digest::MD5.hexdigest ks
      if params['cs'] == 'app' && params['sign'] == key_string && params[:key] = 'abcdefghijkLMNOPQ'
        user_info_hash = user_info uid
        if user_info_hash['code'] == 0
          login_name = user_info_hash['code']['phone']
          password = user_info_hash['code']['password']
          user_login login_name, passowrd
        else
          render :text => res_data_hash
        end
      else
        respond = {}
        return respond['code'] = '参数不正确'
      end
    end

    private



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

    def en_code(password)
      rc4_key = '1bb762f7ce24ceee'
      enc=RC4.new(rc4_key)
      password = enc.encrypt(password).unpack('H*')[0]
    end





  end
