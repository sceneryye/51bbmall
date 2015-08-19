class ApiController < ApplicationController
  layout 'standard'
  def user_login
    @account = Ecstore::Account.new
  end
end
