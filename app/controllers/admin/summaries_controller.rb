class Admin::SummariesController < Admin::BaseController
  require 'json'
  before_filter :find_dates
  def index
    @total_member, @member_before_today, @new_orders_amount, @new_orders_payed_amount = [], [], [], []

    @dates.each do |d|
      today = (Time.parse d).to_i
      today_over = today + 3600 * 24
      @total_member << Ecstore::Account.where('createtime < ?', today_over).count
      @member_before_today << Ecstore::Account.where('createtime < ?', today).count
      select_order = Ecstore::Order.where('createtime < ? AND createtime > ?', today_over, today)
      @new_orders_amount << select_order.count
      @new_orders_payed_amount << select_order.where('pay_status = ?', '1').count
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
    if params[:pay_status].nil?
      @new_orders = Ecstore::Order.where('createtime > ? AND createtime < ?', @start_day[params[:index].to_i],
       @end_day[params[:index].to_i]).paginate(:page => params[:page], :per_page => 20).order('createtime DESC')
    else
      @new_orders = Ecstore::Order.where('createtime > ? AND createtime < ? AND pay_status = ?', @start_day[params[:index].to_i],
       @end_day[params[:index].to_i], '1').paginate(:page => params[:page], :per_page => 20).order('createtime DESC')
    end
  end

  def renew_datas
    today = Time.now.midnight.to_i
    last_time = (Time.parse Ecstore::Summary.last.history_date).to_i
    days = (today - last_time) / 24 / 3600
    (1..days).each do |x|
      Ecstore::Summary.new do |s|
        this_day = Time.zone.at last_time + x.day
        this_day_over = this_day + 1.day
        s.history_date = this_day.strftime('%F')
        s.total_member_today = Ecstore::Account.where('createtime < ?', this_day_over.to_i).count
        s.new_member_today = s.total_member_today - Ecstore::Account.where('createtime < ?', this_day.to_i).count
        select_order = Ecstore::Order.where('createtime < ? AND createtime > ?', this_day_over, this_day)
        s.new_order_today = select_order.count
        s.new_order_payed_today = select_order.where('pay_status = ?', '1')
      end.save
      redirect_to admin_summaries_path
    end

    private

    def find_dates
      @dates = Ecstore::Account.select('createtime').map do |t|
        (Time.zone.at t.createtime).strftime('%F')
      end.uniq.sort {|a, b| b <=> a}
    end
  end
