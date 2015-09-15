class Admin::SummariesController < Admin::BaseController
  def index
    @total_member, @member_before_today = [], []
    @dates = Ecstore::Account.select('createtime').map do |t|
      (Time.zone.at t.createtime).strftime('%F')
    end.uniq.sort {|a, b| b <=> a}

    @dates.each do |d|
      today = (Time.parse d).to_i
      today_over = today + 3600 * 24
      @total_member << Ecstore::Account.where('createtime < ?', today_over).count
      @member_before_today << Ecstore::Account.where('createtime < ?', today).count
    end
  end

  def new_members
    @start_day, @end_day = [], []
    @dates = Ecstore::Account.select('createtime').map do |t|
      (Time.zone.at t.createtime).strftime('%F')
    end.uniq.sort {|a, b| b <=> a}

    @dates.each do |d|
      today = (Time.parse d).to_i
      today_over = today + 3600 * 24
      @start_day << today
      @end_day << today_over
    end
    @new_members = Ecstore::Account.where('createtime > ? AND createtime < ?', @start_day[params[:index].to_i],
     @end_day[params[:index].to_i]).paginate(:page => params[:page], :per_page => 50).order('createtime DESC')
  end

end
