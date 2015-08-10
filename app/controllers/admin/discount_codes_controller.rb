class Admin::DiscountCodesController < Admin::BaseController
  before_filter :require_permission!

  def show

  end
  def index
    @codes = Ecstore::DiscountCode.paginate(:page => params[:page], :per_page => 20).order("member_id DESC,status DESC")

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @logs }
    end
  end

  def edit
   @code = Ecstore::DiscountCode.find_by_code(params[:id])
   @doctor = Ecstore::User.where("member_lv_id=2")
  end

  def update
    @code = Ecstore::DiscountCode.find_by_code(params[:id])

    respond_to do |format|
      if @code.update_attributes(params[:code])
        format.html { redirect_to admin_discount_codes_url, notice: 'Discount_code was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @codes.errors, status: :unprocessable_entity }
      end
    end
  end


end
