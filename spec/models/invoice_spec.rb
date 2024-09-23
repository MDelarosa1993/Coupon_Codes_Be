require "rails_helper"

RSpec.describe Invoice do
  it { should belong_to :merchant }
  it { should belong_to :customer }
  it { should belong_to(:coupon).optional}
  it { should have_many(:invoice_items).dependent(:destroy) }
  it { should have_many(:transactions).dependent(:destroy) }
  it { should validate_inclusion_of(:status).in_array(%w(shipped packaged returned pending)) }

  it 'sets total to $0 if dollar coupon discount exceeds total' do
    merchant = Merchant.create!(name: "Test Merchant")
    customer = Customer.create(first_name: "Mel", last_name: "Rosa")
    item_1 = Item.create!(name: 'Item A', description: 'Description for Item A', unit_price: 100, merchant: merchant)
    item_2 = Item.create!(name: 'Item B', description: 'Description for Item B', unit_price: 50, merchant: merchant)
    invoice = Invoice.create!(customer_id: customer.id, merchant_id: merchant.id, status: 'shipped')
    dollar_coupon = Coupon.create!(name: "Seasonal Discount", code: "SEASONAL", discount_value: 150, active: true, discount_type: 'dollar', merchant: merchant)

    invoice.invoice_items.create!(item: item_1, quantity: 1)
    invoice.invoice_items.create!(item: item_2, quantity: 1)
    invoice.coupon = dollar_coupon
    

    total = invoice.total_for_merchant(merchant.id)

    expect(total).to eq(0)
  end

  it 'applies dollar discount correctly' do
    merchant = Merchant.create!(name: "Test Merchant")
    customer = Customer.create(first_name: "Mel", last_name: "Rosa")
    item_1 = Item.create!(name: 'Item A', description: 'Description for Item A', unit_price: 100, merchant: merchant)
    item_2 = Item.create!(name: 'Item B', description: 'Description for Item B', unit_price: 50, merchant: merchant)
    invoice = Invoice.create!(customer_id: customer.id, merchant_id: merchant.id, status: 'shipped')
    invoice.invoice_items.create!(item: item_1, quantity: 1)
    invoice.invoice_items.create!(item: item_2, quantity: 1)
    dollar_coupon = Coupon.create!(name: "Discount", code: "DISCOUNT", discount_value: 30, active: true, discount_type: 'dollar', merchant: merchant)
    invoice.coupon = dollar_coupon
  
    total = invoice.total_for_merchant(merchant.id)
  
    expect(total).to eq(120)  
  end

  it 'applies percentage discount correctly' do
    merchant = Merchant.create!(name: "Test Merchant")
    customer = Customer.create(first_name: "Mel", last_name: "Rosa")
    item_1 = Item.create!(name: 'Item A', description: 'Description for Item A', unit_price: 100, merchant: merchant)
    item_2 = Item.create!(name: 'Item B', description: 'Description for Item B', unit_price: 50, merchant: merchant)
  
    invoice = Invoice.create!(customer_id: customer.id, merchant_id: merchant.id, status: 'shipped')
    invoice.invoice_items.create!(item: item_1, quantity: 1)
    invoice.invoice_items.create!(item: item_2, quantity: 1)
  
    percent_coupon = Coupon.create!(name: "Seasonal Sale", code: "SEASONAL", discount_value: 20, active: true, discount_type: 'percent', merchant: merchant)
    invoice.coupon = percent_coupon
  
    total = invoice.total_for_merchant(merchant.id)
  
    expect(total).to eq(120)  
  end

  it 'calculates total correctly without any discounts' do
    merchant = Merchant.create!(name: "Test Merchant")
    customer = Customer.create(first_name: "Mel", last_name: "Rosa")
    item_1 = Item.create!(name: 'Item A', description: 'Description for Item A', unit_price: 100, merchant: merchant)
    item_2 = Item.create!(name: 'Item B', description: 'Description for Item B', unit_price: 50, merchant: merchant)
    
    invoice = Invoice.create!(customer_id: customer.id, merchant_id: merchant.id, status: 'shipped')
    invoice.invoice_items.create!(item: item_1, quantity: 1)
    invoice.invoice_items.create!(item: item_2, quantity: 1)
  
    total = invoice.total_for_merchant(merchant.id)
  
    expect(total).to eq(150)  
  end
end