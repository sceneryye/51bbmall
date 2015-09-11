class Admin::SummariesController < ApplicationController
  def index
    today = (Time.parse Time.now.strftime('%F')).to_i
    @new_member = Ecstore::Acount.all.count - Ecstore::Account.where('createtime < today').count
  end

end
