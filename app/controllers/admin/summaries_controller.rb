class Admin::SummariesController < Admin::BaseController
  def index
    @total_member, @user_before_today = [], []
    @dates = Ecstore::Account.all.map do |t|
      (Time.zone.at t.createtime).strftime('%F')
    end.uniq.sort {|a, b| b <=> a}

    @dates.each do |d|
      today = (Time.parse d).to_i
      today_over = today + 3600 * 24
      @total_member << Ecstore::Account.all.count
      @user_before_today << Ecstore::Account.where('createtime < ?', today).count
    end

  end

end
