module SessionsHelper
	def current_account
		return @account unless @account.nil?
		if cookies["MEMBER"].present?
			account_id = cookies["MEMBER"].split("-").first
			@account ||= Ecstore::Account.find_by_account_id(account_id)
		end
	end

	def current_user
		@current_user ||= Ecstore::Account.find_by_login_name(cookies[:loginName])
	end

  def current_user=(account)
    @account = account
  end

	def current_account=(account)
		@account = account
	end

	def signed_in?
		!current_account.nil? || !current_user.nil?
	end

	def sign_in(account,remember_me = nil)
		current_account = account
    current_user = account
		cookies.signed[:_auth_ext] =  account.auth_ext.id if account.auth_ext
		account.user.increment!(:login_count)  if  account.user &&  !account.user.new_record?
         #cookie for ecstore
         expires = nil
         expires = 1.week.from_now if remember_me == "1"
         if Rails.env == "production"
         	cookies[:MEMBER] = {:value=>account.gen_secret_string_for_cookie,:expires=>expires,:domain=>'123.57.35.69'}
         	cookies[:loginName] = {:value=>account.login_name,:expires=>expires,:domain=>'123.57.35.69'}
         	cookies[:UNAME] = {:value=>account.login_name,:expires=>expires,:domain=>'123.57.35.69'}
         	cookies[:MLV] = {:value=>account.user.member_lv_id,:expires=>expires,:domain=>'123.57.35.69'}
         	cookies[:CUR] = {:value=>account.user.cur,:expires=>expires,:domain=>'123.57.35.69'}
         	cookies[:LANG] = {:value=>account.user.lang,:expires=>expires,:domain=>'123.57.35.69'}
         else
         	cookies[:MEMBER] = {:value=>account.gen_secret_string_for_cookie,:expires=>expires}
         	cookies[:loginName] = {:value=>account.login_name,:expires=>expires}
         	cookies[:UNAME] = {:value=>account.login_name,:expires=>expires}
         	cookies[:MLV] = {:value=>account.user.member_lv_id,:expires=>expires}
         	cookies[:CUR] = {:value=>account.user.cur,:expires=>expires}
         	cookies[:LANG] = {:value=>account.user.lang,:expires=>expires}
         end
       end

       def sign_out
       	current_account = nil
        current_user = nil
       	[:MEMBER,:loginName, :loginName, :UNAME,:MLV,:CUR,:LANG].each do |e|
       		if Rails.env == "production"
       			cookies.delete(e.to_s,:domain=>"123.57.35.69")
       		else
       			cookies.delete(e.to_s)
       		end
       	end
       end

       def after_user_sign_in_path
       	root_path
       end

       def login_path
       	subdomain = "bbmall"
       	subdomain = "" if Rails.env == "production"
       	return_url = request.url
       	return_url = request.env["HTTP_REFERER"] if request.xhr?



       	cookies[:unlogin_url] = {:value=>return_url,:domain=>"123.57.35.69"}

    #"http://#{subdomain}.#{request.domain}/passport-login.html"
    "http://123.57.35.69/login"
  end

  def goto_login_path
  	if request.xhr?
  		render :js=>"window.location.href = '#{login_path}'"
  	else
  		redirect_to login_path
  	end
  end

  def site_path
  	return "http://123.57.35.69/" if Rails.env == "development"
  	"http://123.57.35.69/"
  end

  def site
  	return "http://123.57.35.69" if Rails.env == "development"
  	"http://123.57.35.69"
  end


  private

  def authorize_user!

	#  	return true  if params[:agent] == "mobile"

	token = params[:token]
	if token.present?
		@access_log ||=  Logger.new("log/access.log")
		@access_log.info("[#{Time.now}] : #{request.url}")
		return true
	end


	return true if  current_account || current_user
#	  	return true if  session[:admin_id]
	  	# return true if  Rails.env == "development"
	  	if cookies["MEMBER"]
	  		account_id = cookies["MEMBER"].split("-").first
	  		account = Ecstore::Account.find_by_account_id(account_id)
	  		if account
	  			secret_string = account.gen_secret_string_for_cookie
		  		# sign_in(account) if secret_string.split("-")[0..-2] == cookies["MEMBER"].split("-")[0..-2]
		  		return true if secret_string.split("-")[0..-2] == cookies["MEMBER"].split("-")[0..-2]
		  	else
		  		goto_login_path
		  	end

		  else
		  	goto_login_path
		  end
		end

		def authorize_admin!

	#  	return true  if params[:agent] == "mobile"

	token = params[:token]
	if token.present?
		@access_log ||=  Logger.new("log/access.log")
		@access_log.info("[#{Time.now}] : #{request.url}")
		return true
	end


	return true if  current_account
	return true if  session[:admin_id]
	  	# return true if  Rails.env == "development"
	  end

	  def simple_authorize_user!
	  	return  true if  current_account
	  	if cookies["loginName"]
	  		account = Ecstore::Account.find_by_login_name(cookies["loginName"])
	  		if  account
	  			sign_in(account)
	  		else
	  			redirect_to login_path
	  		end
	  	else
	  		redirect_to login_path
	  	end
	  end

	  def finish_auth_path
	  	user_survey_path
	  end
	end
