require 'rails_helper'

require 'rails_helper'

RSpec.describe Coupon, type: :model do
  before do
    @merchant = Merchant.create!(name: "Test Merchant")
  end

  it { should belong_to(:merchant) }
  it { should have_many(:invoices) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:code) }
  it { should validate_inclusion_of(:active).in_array([true, false]) }

  it 'validates uniqueness of code scoped to merchant_id' do
    Coupon.create!(name: "Existing Coupon", code: "UNIQUECODE", active: true, merchant: @merchant)
    new_coupon = Coupon.new(name: "New Coupon", code: "UNIQUECODE", active: true, merchant: @merchant)
    
    expect(new_coupon).not_to be_valid
    expect(new_coupon.errors[:code]).to include("has already been taken")
  end
  describe '#class_method' do
    it 'return merchants based off active=true status of a coupon' do 
      Coupon.create!(name: "Active Coupon", code: "ACTIVE", discount_value: 10, active: true, merchant: @merchant)
      Coupon.create!(name: "Inactive Coupon", code: "Inactive", discount_value: 10, active: false, merchant: @merchant)
      expected = Coupon.sorted_by_active(@merchant, 'active')
      expect(expected).to all(have_attributes(active: true))
    end

    it 'returns only inactive coupons when status is "inactive"' do
      Coupon.create!(name: "Active Coupon", code: "ACTIVE", discount_value: 10, active: true, merchant: @merchant)
      Coupon.create!(name: "Inactive Coupon", code: "Inactive", discount_value: 10, active: false, merchant: @merchant)
      expected = Coupon.sorted_by_active(@merchant, 'inactive') 
      expect(expected).to all(have_attributes(active: false)) 
    end

    it 'returns all coupons when status is neither active nor inactive' do
      Coupon.create!(name: "Active Coupon", code: "ACTIVE", discount_value: 10, active: true, merchant: @merchant)
      Coupon.create!(name: "Inactive Coupon", code: "Inactive", discount_value: 10, active: false, merchant: @merchant)
      expected = Coupon.sorted_by_active(@merchant, 'other') 
      expect(expected.count).to eq(2) 
    end
  end
end
