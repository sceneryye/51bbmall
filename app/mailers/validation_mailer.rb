#encoding:utf-8
class ValidationMailer < ActionMailer::Base
  default from: "邦邦芒<cs@iotps.com>"


  def verify_email(user)
  	@user = user
  	site  = "http://123.57.35.69/"
  	site  = "http://123.57.35.69/" if Rails.env == "production"
  	@verify_email_url = "#{site}/validation/verify_email?u=#{user.member_id}&token=#{user.email_code}"
  	mail(:to => user.email, :subject => "邦邦芒验证邮件")
  end


end
