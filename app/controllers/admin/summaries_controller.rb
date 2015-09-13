class Admin::SummariesController < Admin::BaseController
  def index
    @total_member, @member_before_today, @new_members = [], [], []
    @dates = Ecstore::Account.all.map do |t|
      (Time.zone.at t.createtime).strftime('%F')
    end.uniq.sort {|a, b| b <=> a}

    @dates.each do |d|
      today = (Time.parse d).to_i
      today_over = today + 3600 * 24
      @total_member << Ecstore::Account.where('createtime < ?', today_over).count
      @member_before_today << Ecstore::Account.where('createtime < ?', today).count

      @new_members = Ecstore::Account.where('createtime > ? and createtime < ?', today, today_over )
    end

  end

end
