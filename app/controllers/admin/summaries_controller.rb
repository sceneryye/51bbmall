class Admin::SummariesController < Admin::BaseController
  before_filter :find_dates
  def index
    @total_member, @member_before_today, @new_orders_amount, @new_orders_payed_amount = [], [], [], []
    
    @dates.each do |d|
      today = (Time.parse d).to_i
      today_over = today + 3600 * 24
      @total_member << Ecstore::Account.where('createtime < ?', today_over).count
      @member_before_today << Ecstore::Account.where('createtime < ?', today).count
      @new_orders_amount << Ecstore::Order.where('createtime < ? AND createtime > ?', today_over, today).count
      @new_orders_payed_amount << Ecstore::Order.where('createtime < ? AND createtime > ? AND pay_status = ?', today_over, today, '1').count
    end
  end

  def new_members
    @start_day, @end_day = [], []
    
    @dates.each do |d|
      today = (Time.parse d).to_i
      today_over = today + 3600 * 24
      @start_day << today
      @end_day << today_over
    end
    @new_members = Ecstore::Account.where('createtime > ? AND createtime < ?', @start_day[params[:index].to_i],
     @end_day[params[:index].to_i]).paginate(:page => params[:page], :per_page => 50).order('createtime DESC')
  end

  def new_orders
    @start_day, @end_day = [], []    
    @dates.each do |d|
      today = (Time.parse d).to_i
      today_over = today + 3600 * 24
      @start_day << today
      @end_day << today_over
    end
    @new_orders = Ecstore::Order.where('createtime > ? AND createtime < ?', @start_day[params[:index].to_i],
     @end_day[params[:index].to_i]).paginate(:page => params[:page], :per_page => 20).order('createtime DESC')
    @new_orders_payed = Ecstore::Order.where('createtime > ? AND createtime < ? AND pay_status = ?', @start_day[params[:index].to_i],
     @end_day[params[:index].to_i], '1').paginate(:page => params[:page], :per_page => 20).order('createtime DESC')
  end

  private

  def find_dates
    @dates = Ecstore::Account.select('createtime').map do |t|
      (Time.zone.at t.createtime).strftime('%F')
    end.uniq.sort {|a, b| b <=> a}
  end
end
