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

  describe '#instance_methods' do 
    it 'raises an error if more than 5 coupons are active for a merchant' do
      merchant = Merchant.create!(name: "Sample Merchant")
      Coupon.create!(name: "Buy One Get One 50", code: "BOGO50", discount_value: 50, active: true, discount_type: 'percent', merchant: merchant)
      Coupon.create!(name: "Buy One Get One 40", code: "BOGO40", discount_value: 40, active: true, discount_type: 'percent', merchant: merchant)
      Coupon.create!(name: "Buy One Get One 30", code: "BOGO30", discount_value: 30, active: true, discount_type: 'percent', merchant: merchant)
      Coupon.create!(name: "Buy One Get One 20", code: "BOGO20", discount_value: 20, active: true, discount_type: 'percent', merchant: merchant)
      Coupon.create!(name: "Buy One Get One 10", code: "BOGO10", discount_value: 10, active: true, discount_type: 'percent', merchant: merchant)    
      new_coupon = Coupon.new(name: "Buy One Get One 60", code: "BOGO60", discount_value: 10, active: true, discount_type: 'percent', merchant: merchant) 

      expect(new_coupon.valid?).to be_falsy
      expect(new_coupon.errors[:base]).to include("This Merchant already has 5 active coupons.")
    end

    it 'does not allow deactivation if there are pending invoices' do
      merchant = Merchant.create!(name: "Test Merchant")
      coupon = Coupon.create!(name: "Seasonal Discount", code: "SEASONAL", discount_value: 20, active: true, discount_type: 'percent', merchant: merchant)
      customer = Customer.create!(first_name: "Mel", last_name: "Rose")
      Invoice.create!(merchant: merchant, customer: customer, coupon: coupon, status: "pending")
  
      coupon.active = false
      coupon.pending_invoices
  
      expect(coupon.errors[:base]).to include("Cannot deactivate coupon with pending invoices.")
    end

    it 'returns true when all items belong to the same merchant' do 
      merchant = Merchant.create!(name: "Test Merchant")
      coupon = Coupon.create!(name: "Seasonal Discount", code: "SEASONAL", discount_value: 20, active: true, discount_type: 'percent', merchant: merchant)
      item_1 = Item.create!(name: 'Item A', description: 'Description for Item A', unit_price: 100, merchant: merchant)
      item_2 = Item.create!(name: 'Item B', description: 'Description for Item B', unit_price: 200, merchant: merchant)

      items = [item_1, item_2] 
      expect(coupon.applicable_to?(items)).to be(true)
    end

    it 'returns false when some items do not belong to the same merchant' do
      merchant_a = Merchant.create!(name: "Merchant A")
      merchant_b = Merchant.create!(name: "Merchant B")
      coupon = Coupon.create!(name: "Seasonal Discount", code: "SEASONAL", discount_value: 20, active: true, discount_type: 'percent', merchant: merchant_a)
      item_1 = Item.create!(name: 'Item A', description: 'Description for Item A', unit_price: 100, merchant: merchant_a)
      item_2 = Item.create!(name: 'Item B', description: 'Description for Item B', unit_price: 200, merchant: merchant_b)

      items = [item_1, item_2] 
      expect(coupon.applicable_to?(items)).to be(false)
    end
  end
end
