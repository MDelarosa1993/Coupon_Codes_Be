require 'rails_helper'

RSpec.describe CouponSerializer, type: :serializer do
  it 'serializes a single coupon with the correct attributes' do
    merchant = Merchant.create!(name: "Sample Merchant")
    coupon = Coupon.create!(name: "Seasonal Discount", code: "SEASONAL", discount_value: 20, active: true, discount_type: 'percent', merchant: merchant)
    
    customer = Customer.create!(first_name: "Mel", last_name: "Rose")

    serialized_coupon = CouponSerializer.new(coupon, { single_coupon: true }).serializable_hash

    expect(serialized_coupon[:data][:attributes]).to include(
      id: coupon.id,
      name: coupon.name,
      code: coupon.code,
      discount_value: coupon.discount_value,
      active: coupon.active,
      discount_type: coupon.discount_type,
      merchant_id: coupon.merchant_id
    )
  end

  it 'calculates usage_count correctly for a single coupon' do
    merchant = Merchant.create!(name: "Sample Merchant")
    coupon = Coupon.create!(name: "Seasonal Discount", code: "SEASONAL", discount_value: 20, active: true, discount_type: 'percent', merchant: merchant)
    customer = Customer.create!(first_name: "Mel", last_name: "Rose")
    Invoice.create!(merchant_id: merchant.id, customer_id: customer.id, coupon_id: coupon.id, status: "pending")
    Invoice.create!(merchant_id: merchant.id, customer_id: customer.id, coupon_id: coupon.id, status: "shipped")
    puts "Created invoices: #{coupon.invoices.inspect}"
    serialized_coupon = CouponSerializer.new(coupon, { single_coupon: true }).serializable_hash
    
    expect(serialized_coupon[:data][:attributes][:usage_count]).to eq(2) # Expecting 2 invoices
  end

  it 'sets usage_count to 0 when not a single coupon' do
    merchant = Merchant.create!(name: "Test Merchant")
    coupon = Coupon.create!(name: "Buy One Get One", code: "BOGO", discount_value: 50, discount_type: 'percent', active: true, merchant: merchant)

    serialized_coupon = CouponSerializer.new(coupon, { single_coupon: false }).serializable_hash

    expect(serialized_coupon[:data][:attributes][:usage_count]).to eq(0)
  end
end