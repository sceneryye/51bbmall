#encoding:utf-8
require 'digest/md5'
#require 'rc4'
require 'rest-client'



class Auth::BbmallController < ApplicationController


  skip_before_filter :authorize_user!

  def index 
    #rc4_key='1bb762f7ce24ceee'
    #pw='6D6760606361'
    #str1='sf334dfsf'

    #dec=RC4.new(rc4_key)
    #enc=RC4.new(rc4_key)
    #encrypted = enc.encrypt(str1)
    #decrypted = dec.decrypt(encrypted)
    #eql = (str1 == decrypted)
    #return render :text => eql

    

    brand_id = 'itd'
    client_id = 'itd'
    #phone = params[:phone]
    phone = '15800694393' 
    key = '2c31b08f6a79f06f'
    rc4_key = '1bb762f7ce24ceee'
    ts = Time.now.to_i

    info_hash={}
    
    info_hash[:brand_id] = brand_id
    info_hash[:client_id] = client_id #'test'
    info_hash[:phone] = phone
    info_hash[:ts] = ts
    
    

    unsign = info_hash.map {|key,val| "#{val}"}.join('') + ts.to_s + key
    info_hash[:sign]  = Digest::MD5.hexdigest(unsign)

    json =  info_hash.to_json
    #return render :text => json
    

    url = 'http://103.16.125.100:9018/user_reg' #生产地址
    #url = 'http://www.baidu.com'

    #RestClient.get(url) 
    #return render :text => 'Is this OK, too?'
    res_data = RestClient.get url, json
      #res_data_xml = res_data.force_encoding('gb2312').encode
      res_data_hash = ActiveSupport::JSON.decode(res_data)
      return render :text=>res_data_hash

      if res_data_hash['code']=='0'        

        # 登录或注册
        uid = res_data_hash['data']['uid']
        pw_enc = res_data_hash['data']['password']
        expires_in = 7200

        auth_ext = Ecstore::AuthExt.where(:provider=>"51bbmall",
          :uid=>uid).first_or_initialize(
          #:access_token=>pw_enc,
          :expires_at=>expires_in + Time.now.to_i,
          :expires_in=>expires_in)

          login_name = phone
          check_user = Ecstore::Account.find_by_login_name(login_name)

          return redirect_to '/' if check_user

          now = Time.now
          @account - Ecstore::Account.new do |ac|
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
        else
          message = res_data_hash['code'] + ":#{res_data_hash['msg']}"
          return render :text=>message
        end 
      end

      def auth_login
        shop_id = 48
        auth_ext = Ecstore::AuthExt.find_by_id(cookies.signed[:_auth_ext].to_i) if cookies.signed[:_auth_ext]
        session[:from] = "external_auth"

        if auth_ext&&!auth_ext.expired?&&auth_ext.provider == '51bbmall'
          if auth_ext.account.nil?
            cookies.delete :_auth_ext   
            # redirect_to  Email139.authorize_url
          else
            sign_in(auth_ext.account)
            return redirect_to "/mobile/#{shop_id}/shop"
          end   
        end

        brand_id = 'itd'
        client_id = 'itd'
        #phone = params[:phone]
        phone = '15900300040' 
        key = '2c31b08f6a79f06f'
        rc4_key = '1bb762f7ce24ceee'
        ts = Time.now.to_i



        info_hash={}

        info_hash[:brand_id] = brand_id
        info_hash[:client_id] = client_id #'test'
        info_hash[:account] = params[:account]
        info_hash[:password] = params[:password]



        unsign = info_hash.map {|key,val| "#{val}"}.join('') + ts.to_s + key
        info_hash[:sign]  = Digest::MD5.hexdigest(unsign)

        json =  info_hash.to_json


        url = 'http://119.147.164.184:9018/user_login' #测试地址
        #url = 'http://www.baidu.com'

        RestClient.get(url) 
        res_data = RestClient.post url, json, {:content_type => :json}
          #res_data_xml = res_data.force_encoding('gb2312').encode
          res_data_hash = ActiveSupport::JSON.decode(res_data)
         #return render :text=>res_data_hash

         if res_data_hash[:code] == 0
          sign_in(info_hash[:account])
          return redirect_to '/'
        else
          message = res_data_hash['code'] + ":#{res_data_hash['msg']}"
          return render :text=>message
        end


      end


      def callback

    #return redirect_to(site_path) if params[:error].present?     
    #shop_id =48

    #return_url= session[:return_url]
    #session[:return_url]=''
    #return_url ="/mobile/#{shop_id}/shop"
    
    
    #token = Email139.request_token(params[:code])
    uid = res_data_hash['data']['uid']
    pw_enc = res_data_hash['data']['password']
    expires_in = 7200


    auth_ext = Ecstore::AuthExt.where(:provider=>"email139",
      :uid=>sid).first_or_initialize(
      :access_token=>sid,
      :expires_at=>expires_in + Time.now.to_i,
      :expires_in=>expires_in)



      if auth_ext.new_record? || auth_ext.account.nil? || auth_ext.account.user.nil?
      # client = Email139.new(:access_token=>sid,:expires_at=>expires_in + Time.now.to_i)
      # auth_user = client.get('users/show.json',:uid=>sid)

      # logger.info auth_user.inspect
      login_name = sid
      check_user = Ecstore::Account.find_by_login_name(login_name)
      
      login_name = "#{login_name}_#{rand(9999)}" if check_user

      now = Time.now

      @account = Ecstore::Account.new  do |ac|
        #account
        ac.login_name = login_name
        ac.login_password = '123456'
        ac.account_type ="member"
        ac.createtime = now.to_i
        ac.auth_ext = auth_ext

            ac.supplier_id = 78  #贸威客户
          end

          Ecstore::Account.transaction do
            if @account.save!(:validate => false)
              @user = Ecstore::User.new do |u|
                u.member_id = @account.account_id
                u.email = "#{user_number}@139.com"
                u.mobile = user_number
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

          shop_id = 48
          shop_client = Ecstore::ShopClient.where(:member_id=>@account.account_id,:shop_id=>shop_id)
          if shop_client.size ==0
            Ecstore::ShopClient.new do |sc|
              sc.member_id = @account.account_id
              sc.shop_id = shop_id
            end.save
          end
        else

          sign_in(auth_ext.account,'1')
          return render :text=>auth_ext.account

        end



        redirect_to return_url

    #rescue
    # redirect_to(site_path)
  end



  def cancel
  end
end

