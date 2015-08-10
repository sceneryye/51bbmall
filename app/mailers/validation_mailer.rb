#encoding:utf-8
class ValidationMailer < ActionMailer::Base
  default from: "TRADE-V<cs@iotps.com>"


  def verify_email(user)
  	@user = user
  	site  = "http://www.baohengbio.com/"
  	site  = "http://www.baohengbio.com/" if Rails.env == "production"
  	@verify_email_url = "#{site}/validation/verify_email?u=#{user.member_id}&token=#{user.email_code}"
  	mail(:to => user.email, :subject => "佐康茶验证邮件")
  end


end
