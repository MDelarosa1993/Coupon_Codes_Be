class Api::V1::Merchants::CouponsController < ApplicationController

  def show 
    coupon = Coupon.find(params[:id])
    render json: CouponSerializer.new(coupon)
  end

  def index
    merchant = Merchant.find(params[:merchant_id])
    coupons = Coupon.sorted_by_active(merchant, params[:sort_by])
    render json: CouponSerializer.new(coupons)
  end

  def create
    merchant = Merchant.find(params[:merchant_id])
    coupon = merchant.coupons.create!(coupon_params)
    if coupon.save 
      render json: CouponSerializer.new(coupon), status: :created 
    else
      render json: ErrorSerializer.serialize(coupon.errors), status: :unprocessable_entity 
    end
  end

  def update 
    coupon = Coupon.find(params[:id])
  
    if coupon.update(coupon_params)
      render json: CouponSerializer.new(coupon)
    else
      render json: ErrorSerializer.format_errors(coupon.errors), status: :unprocessable_entity
    end
  end
  

  private

  def coupon_params
    params.require(:coupon).permit(:name, :code, :discount_value, :active, :discount_type)
  end
end
