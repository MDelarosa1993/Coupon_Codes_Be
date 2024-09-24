class Api::V1::Merchants::CouponsController < ApplicationController

  def show 
    coupon = Coupon.find(params[:id])
    render json: CouponSerializer.new(coupon, {single_coupon: true})
  end
  

  def index
    merchant = Merchant.find(params[:merchant_id])
    coupons = Coupon.sorted_by_active(merchant, params[:sort_by])
    render json: CouponSerializer.new(coupons)
  end

  def create
    merchant = Merchant.find(params[:merchant_id])
    coupon = merchant.coupons.create!(coupon_params) # This will raise an error if invalid
    render json: CouponSerializer.new(coupon), status: :created
  end

  def update
    coupon = Coupon.find(params[:id])
    coupon.update!(coupon_params) # This will raise an error if invalid
    render json: CouponSerializer.new(coupon)
  end
  

  private

  def coupon_params
    params.require(:coupon).permit(:name, :code, :discount_value, :active, :discount_type)
  end
end
