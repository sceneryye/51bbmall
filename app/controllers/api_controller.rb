class ApiController < ApplicationController
  layout 'standard'
  def user_login
    @account = Ecstore::Account.new
  end

  def change_pwd
    @account = Ecstore::Account.new
  end

  def change_phone
    @account = Ecstore::Account.new
  end

  def validate_code
    @account = Ecstore::Account.new
  end
end
