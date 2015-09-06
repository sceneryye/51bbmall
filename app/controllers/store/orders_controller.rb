#encoding:utf-8
class Store::OrdersController < ApplicationController
  before_filter :authorize_user!
  layout 'order'

  
  def share_order

    @order =Ecstore::Order.find_by_order_id(params[:id])
    
  end

  def out_inventory
    return_url =  request.env["HTTP_REFERER"]
    return_url =  member_goods_url if return_url.blank?

    @inventory = Ecstore::Inventory.where(:member_id=>current_account,:product_id=>params[:id]).first

    if @inventory.blank?
      #全部出库，删除记录
    else
      #部分出库，修改数量
      quantity =  @inventory.quantity - @inventory.quantity
      Ecstore::Inventory.where(:member_id=>current_account,:product_id=>params[:id]).update_all(:quantity=>quantity)
    end


    Ecstore::InventoryLog.new do |inventory_log|
      inventory_log.in_or_out =false
      inventory_log.member_id = @inventory.member_id
      inventory_log.goods_id =@inventory.goods_id
      inventory_log.product_id =@inventory.product_id
      inventory_log.price = @inventory.price
      inventory_log.quantity =@inventory.quantity
      inventory_log.name =@inventory.name
      inventory_log.bn = @inventory.bn
      inventory_log.barcode = @inventory.barcode
      inventory_log.createtime = Time.now.to_i
    end.save


    redirect_to return_url
  end

  def to_inventory
    return_url =  request.env["HTTP_REFERER"]
    return_url =  member_goods_url if return_url.blank?

    @order_item =  Ecstore::OrderItem.find(params[:id])

    @new_inventory = Ecstore::Inventory.where(:member_id=>current_account,:product_id=>@order_item.product_id).first

    @inventory =  Ecstore::Inventory.new

    if @new_inventory.blank?
      @inventory.member_id = @order_item.order.member_id
      @inventory.goods_id =@order_item.goods_id
      @inventory.product_id =@order_item.product_id
      @inventory.price = @order_item.price
      @inventory.quantity =@order_item.nums
      @inventory.name =@order_item.name
      @inventory.bn = @order_item.bn
      @inventory.barcode = @order_item.product.barcode
      @inventory.save
    else
      quantity =  @new_inventory.quantity + @order_item.nums
      Ecstore::Inventory.where(:member_id=>current_account,:product_id=>@order_item.product_id).update_all(:quantity=>quantity)
    end


    Ecstore::InventoryLog.new do |inventory_log|
      inventory_log.in_or_out =true
      inventory_log.order_item_id=@order_item.item_id
      inventory_log.order_id = @order_item.order_id
      inventory_log.member_id = @order_item.order.member_id
      inventory_log.goods_id =@order_item.goods_id
      inventory_log.product_id =@order_item.product_id
      inventory_log.price = @order_item.price
      inventory_log.quantity =@order_item.nums
      inventory_log.name =@order_item.name
      inventory_log.bn = @order_item.bn
      inventory_log.barcode = @order_item.product.barcode
      inventory_log.createtime = Time.now.to_i
    end.save


    @order_item.update_attribute :storaged, true
    redirect_to return_url
  end

  def index
    if  @user

      @orders =  @user.orders.order("createtime desc").paginate(:page=>params[:page],:per_page=>10)
    else
      return_url={:return_url => "/goods"}.to_query
      redirect_to "/login?#{return_url}"
    end
  end

 
  def show

    @order = Ecstore::Order.find_by_order_id(params[:id])
    render :layout=>"member"
  end


  def create

    @advance = user_wallet current_user.uid     

    if addr = Ecstore::MemberAddr.find_by_addr_id(params[:member_addr])
      ["name","area","addr","zip","tel","mobile"].each do |key,val|
        params[:order].merge!("ship_#{key}"=>addr.attributes[key])
      end
    else

    end
    

    return_url=params[:return_url]
    platform=params["platform"];

    supplier_id = 1


    params[:order].merge!(:ip=>request.remote_ip)
    params[:order].merge!(:member_id=>@user.member_id)
    params[:order].merge!(:supplier_id=>supplier_id)
    params[:order].merge!(:status=>'active')

    #=====推广佣金计算=======
    recommend_user = session[:recommend_user]
    if recommend_user==nil
      recommend_user= @user.login_name
    end
    params[:order].merge!(:recommend_user=>recommend_user)
    #return render :text=>params[:order]
    #====================
    
    @order = Ecstore::Order.new params[:order]
    @order.final_amount = @order.total_amount - @order.part_pay
    if recommend_user == nil
      @order.commission=0
    end
    #debug_line_item =''
    @line_items.each do |line_item|
      product = line_item.product
      good = line_item.good

      #     if product || good
      @order.order_items << Ecstore::OrderItem.new do |order_item|
        order_item.product_id = product.product_id
        order_item.bn = product.bn
        order_item.name = product.name
        if cookies[:MLV] == "10"
          order_item.price = product.bulk
        else∂
          order_item.price = product.price
        end
        order_item.goods_id = good.goods_id
        order_item.type_id = good.type_id
        order_item.nums = line_item.quantity.to_i
        order_item.item_type = "product"
        if params[:cart_total_final].nil?
          order_item.amount = order_item.price * order_item.nums
        else
          order_item.amount =  params[:cart_total_final]
        end

        product_attr = {}
        # product.spec_desc["spec_value"].each  do |spec_id,spec_value|
        # 	spec = Ecstore::Spec.find_by_spec_id(spec_id)
        # 	product_attr.merge!(spec_id=>{"label"=>spec.spec_name,"value"=>spec_value})
        # end
        order_item.addon = { :product_attr => product_attr }.serialize

        # @order.total_amount += order_item.calculate_amount
      end
      #     else
      #       debug_line_item +=line_item.id.to_s + '|'
      #    end
    end
    #if debug_line_item
    #  return render :text=>debug_line_item
    #end
    # ==== promotion gifts =====
    gifts = params[:gifts] || []
    gifts.each do |gift_id|
      gift = Ecstore::Product.find_by_product_id(gift_id)
      @order.order_items  << Ecstore::OrderItem.new do |order_item|
        order_item.product_id = gift_id
        order_item.goods_id = gift.goods_id
        order_item.type_id = gift.good.type_id if gift.good
        order_item.bn = gift.bn
        order_item.name = gift.name
        order_item.price = gift.price
        order_item.nums = 1
        order_item.item_type = 'gift'
        order_item.addon = nil
        order_item.amount = 0
      end
    end


    if @pmtable
      # ==== coupons======
      codes = params[:coupon].present? ? params[:coupon][:codes] : []
      coupons =  codes.collect do |code|
        Ecstore::NewCoupon.check_and_find_by_code(code)
      end.compact

      coupons.each do |coupon|
        @order.order_pmts << Ecstore::OrderPmt.new do |order_pmt|
          order_pmt.pmt_type = 'coupon'
          order_pmt.pmt_id = coupon.id
          order_pmt.pmt_amount = coupon.pmt_amount(@line_items)
          order_pmt.pmt_name = coupon.name
          order_pmt.pmt_desc = coupon.desc
          order_pmt.coupon_code = coupon.current_code
        end
      end
      # === goods promotions =====
      @goods_promotions = Ecstore::Promotion.matched_goods_promotions(@line_items)
      @goods_promotions.each do |promotion|
        @order.order_pmts << Ecstore::OrderPmt.new do |order_pmt|
          order_pmt.pmt_type = 'goods'
          order_pmt.pmt_id = promotion.id
          order_pmt.pmt_amount = promotion.goods_pmt_amount(@line_items)
          order_pmt.pmt_name = promotion.name
          order_pmt.pmt_desc = promotion.desc
        end
      end
      # ==== order promotions =====
      @order_promotions = Ecstore::Promotion.matched_promotions(@line_items)
      @order_promotions.each do |promotion|
        @order.order_pmts << Ecstore::OrderPmt.new do |order_pmt|
          order_pmt.pmt_type = 'order'
          order_pmt.pmt_id = promotion.id
          order_pmt.pmt_amount = promotion.pmt_amount(@line_items)
          order_pmt.pmt_name = promotion.name
          order_pmt.pmt_desc = promotion.desc
        end
      end
    end

  if @order.save

    @line_items.delete_all

    Ecstore::OrderLog.new do |order_log|
      order_log.rel_id = @order.order_id
      order_log.op_id = @order.member_id
      order_log.op_name = @user.login_name
      order_log.alttime = @order.createtime
      order_log.behavior = 'creates'
      order_log.result = "SUCCESS"
      order_log.log_text = "订单创建成功！"
    end.save

    if return_url.nil?        
      redirect_to order_path(@order)
    else
      redirect_to return_url
    end
  else
    @addrs =  @user.member_addrs
    @def_addr = @addrs.where(:def_addr=>1).first || @addrs.first
    @coupons = @user.usable_coupons
    render :new
  end

end

def new
    # @order = Ecstore::Order.new

    @addrs =  @user.member_addrs
    
    @def_addr = @addrs.where(:def_addr=>1).first || @addrs.first

    if @pmtable
      @order_promotions = Ecstore::Promotion.matched_promotions(@line_items)
      @goods_promotions = Ecstore::Promotion.matched_goods_promotions(@line_items)
      @coupons = @user.usable_coupons
    end

    user_wallet_url = 'http://103.16.125.100:9018/user_wallet'
    info_hash = {}
    uid = info_hash[:uid] = current_user.uid if current_user   
    info_hash = params_info(info_hash)      
    res_data = RestClient.get user_wallet_url, {:params => info_hash}
    res_data_hash = ActiveSupport::JSON.decode res_data

    if res_data_hash['code'] == 0
      @advance = res_data_hash['data']['balance'] / 100
    else
      render :text => message_error = "错误：#{res_data_hash['msg']}"
    end

end

  

  def addr_detail
    @addr = Ecstore::MemberAddr.find(params[:id])
    supplier_id=params[:supplier_id]
    @supplier = Ecstore::Supplier.find(supplier_id)
    @method = :put

    render :layout=>@supplier.layout
  end

  def edit_addr
   @addr = Ecstore::MemberAddr.find(params[:id])
   if @addr.update_attributes(params[:addr])
    respond_to do |format|
     format.js
     format.html { redirect_to "/orders/new_mobile?platform=mobile" }
   end
 else
     render 'error.js' #, status: :unprocessable_entity
   end
 end


 

  def share
    wechat_user = params[:FromUserName]
    if @user
      wechat_user=@user.account.login_name
    end
    @supplier = Ecstore::Supplier.find(params[:supplier_id])
    @share=0
    @sharelast = 0
    if wechat_user
      @order_all = Ecstore::Order.where(:recommend_user=>wechat_user,:pay_status=>'1').select("sum(commission) as share").group(:recommend_user).first

      #return render :text=>@order.final_amount
      if @order_all
        @share = @order_all.share.round(2)
        @order_last =Ecstore::Order.where(:recommend_user=>wechat_user,:pay_status=>'1').order("createtime desc").first
        if @order_last
          @sharelast = @order_last.commission
        end
      end
    end

  end


  def pay
    @order  = Ecstore::Order.find_by_order_id(params[:id])
    if @order &&@order.status == 'active' && @order.pay_status == '0'
      @order.update_attribute :payment, params[:order][:payment]
    else
      render :text=>"不存在的订单不能支付!"
    end
  end

  def detail
    @order  = Ecstore::Order.find_by_order_id(params[:id])
    render :layout=>"member"
  end

  def check_coupon
    codes = params[:codes] || []

    now_code = codes.delete_at(0)
    now_coupon = Ecstore::NewCoupon.check_and_find_by_code(now_code)

    unless now_coupon
      return render :js=>"alert('该优惠券不存在')"
    end

    @coupons = codes.collect do |code|
      Ecstore::NewCoupon.check_and_find_by_code(code)
    end.compact #.sort { |x,y| y.priority <=> x.priority }

    if @coupons.size > 0 && @coupons.include?(now_coupon)
      render :js=>"alert('同一种的优惠券只能使用一次')"
      return
    end

    @coupons << now_coupon if now_coupon

    @coupons.sort! { |x,y| y.priority <=> x.priority }

    @useable = {}
    exclusive = false

    @coupons.each do |coupon|
      if coupon.test_condition(@line_items)
        if !exclusive
          @useable[coupon.current_code] =  true
        else
          @useable[coupon.current_code] =  false
        end

        exclusive = coupon.exclusive
      else
        @useable[coupon.current_code] =  false
      end
    end

    @coupon_amount = @coupons.select do |coupon|
      @useable[coupon.current_code]
    end.collect { |coupon| coupon.pmt_amount(@line_items) }.inject(:+)

  end



  def destroyaddr

    @addr = Ecstore::MemberAddr.find(params[:addr_idsss])            ### 删除地址
    @addr.destroy

  end


  def serach_order
    departure= params[:departure]
    arrival= params[:arrival]
    @un= Ecstore::Express.serachall(departure,arrival)
  end

end
