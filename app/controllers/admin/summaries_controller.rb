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

    idisplaystart   = params[:iDisplayStart]
    idisplaylength  = params[:iDisplayLength]
    secho = params[:sEcho]

    itotalrecords =  @dates.length
    items = @dates.limit(idisplaylength).offset(idisplaystart)

    items.each do |itme|
      today = (Time.parse item).to_i
      today_over = today + 3600 * 24
      item_array = []
      item_array << item
      item_array << Ecstore::Account.where('createtime < ?', today_over).count
      item_array << Ecstore::Order.where('createtime < ? AND createtime > ?', today_over, today).count - Ecstore::Account.where('createtime < ?', today).count
      item_array << Ecstore::Order.where('createtime < ? AND createtime > ?', today_over, today).count
      item_array << Ecstore::Order.where('createtime < ? AND createtime > ? AND pay_status = ?', today_over, today, '1').count
    end
    json_hash.store("aaData",item_array)
    json_hash.store("iTotalRecords",itotalrecords)
    json_hash.store("iTotalDisplayRecords",itotalrecords)
    json_hash.store("sEcho",secho)
    render json: json_hash
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

  private

  def find_dates
    @dates = Ecstore::Account.select('createtime').map do |t|
      (Time.zone.at t.createtime).strftime('%F')
    end.uniq.sort {|a, b| b <=> a}
  end
end
