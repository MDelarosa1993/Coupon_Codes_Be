require 'rails_helper'

RSpec.describe Coupon, type: :model do
  before do
    @merchant = Merchant.create!(name: "Test Merchant")
  end

  it { should belong_to(:merchant) }
  it { should have_many(:invoices) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:code) }
  it { should validate_presence_of(:discount_value) }
  it { should validate_numericality_of(:discount_value).is_greater_than(0) }
  
  it 'validates uniqueness of code scoped to merchant_id' do
    Coupon.create!(name: "Existing Coupon", code: "UNIQUECODE", discount_value: 20, active: true, discount_type: 'dollar', merchant: @merchant)
    new_coupon = Coupon.new(name: "New Coupon", code: "UNIQUECODE", discount_value: 10, active: true, discount_type: 'dollar', merchant: @merchant)
    
    expect(new_coupon).not_to be_valid
    expect(new_coupon.errors[:code]).to include("has already been taken")
  end
  describe '#class_method' do
    it 'return merchants based off active=true status of a coupon' do 
      Coupon.create!(name: "Active Coupon", code: "ACTIVE", discount_value: 10, active: true,discount_type: 'dollar', merchant: @merchant)
      Coupon.create!(name: "Inactive Coupon", code: "Inactive", discount_value: 10, active: false,discount_type: 'dollar', merchant: @merchant)
      expected = Coupon.sorted_by_active(@merchant, 'active')
      expect(expected).to all(have_attributes(active: true))
    end

    it 'returns only inactive coupons when status is "inactive"' do
      Coupon.create!(name: "Active Coupon", code: "ACTIVE", discount_value: 10, active: true,discount_type: 'dollar', merchant: @merchant)
      Coupon.create!(name: "Inactive Coupon", code: "Inactive", discount_value: 10, active: false,discount_type: 'dollar', merchant: @merchant)
      expected = Coupon.sorted_by_active(@merchant, 'inactive') 
      expect(expected).to all(have_attributes(active: false)) 
    end

    it 'returns all coupons when status is neither active nor inactive' do
      Coupon.create!(name: "Active Coupon", code: "ACTIVE", discount_value: 10, active: true,discount_type: 'dollar', merchant: @merchant)
      Coupon.create!(name: "Inactive Coupon", code: "Inactive", discount_value: 10, active: false,discount_type: 'dollar', merchant: @merchant)
      expected = Coupon.sorted_by_active(@merchant, 'other') 
      expect(expected.count).to eq(2) 
    end
  end
end
