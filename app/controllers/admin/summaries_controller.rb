class Admin::SummariesController < Admin::BaseController
  require 'json'
  before_filter :find_dates
  def index
    @total_member, @member_before_today, @new_orders_amount, @new_orders_payed_amount = [], [], [], []
    @total_member_today = Ecstore::Account.all.count
    @new_member_today = @total_member_today - Ecstore::Summary.all[-1].total_member_today
    select_order = Ecstore::Order.where('createtime > ?', Time.now.midnight.to_i)
    @new_order_today = select_order.count
    @new_order_payed_today = select_order.where('pay_status = ?', '1').count
  end

  def new_members
    @start_day, @end_day = [], []

    @dates.each do |d|
      today = (Time.parse d).to_i
      today_over = today + 3600 * 24
      @start_day << today
      @end_day << today_over
    end
    if params[:index]
      @new_members = Ecstore::Account.where('createtime > ? AND createtime < ?', @start_day[params[:index].to_i],
       @end_day[params[:index].to_i]).paginate(:page => params[:page], :per_page => 50).order('createtime DESC')
    else
      @new_members = Ecstore::Account.where('createtime > ?', Time.now.midnight.to_i).paginate(:page => params[:page], :per_page => 50).order('createtime DESC')
    end
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
    last_time = (Time.parse Ecstore::Summary.all[-1].history_date).to_i
    days = (today - last_time) / 24 / 3600
    if days > 0
      (1..days - 1).each do |x|
        Ecstore::Summary.new do |s|
          this_day = last_time + x.day
          this_day_over = this_day + 1.day
          s.history_date = (Time.zone.at this_day).strftime('%F')
          s.total_member_today = Ecstore::Account.where('createtime < ?', this_day_over).count
          s.new_member_today = s.total_member_today - Ecstore::Account.where('createtime < ?', this_day).count
          select_order = Ecstore::Order.where('createtime < ? AND createtime > ?', this_day_over, this_day)
          s.new_order_today = select_order.count
          s.new_order_payed_today = select_order.where('pay_status = ?', '1').count
        end.save
      end
    end
    redirect_to admin_summaries_path
  end

  private

  def find_dates
    @summaries = Ecstore::Summary.paginate(:page => params[:page], :per_page => (params['per_page'].nil? ? 10 : params['per_page'])).order('id DESC')
    @dates = @summaries.map &:history_date
  end
end
