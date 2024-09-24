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

  it 'calculates total correctly without any discounts' do
    merchant = Merchant.create!(name: "Test Merchant")
    customer = Customer.create!(first_name: "Mel", last_name: "Rosa")
    item_1 = Item.create!(name: 'Item A', description: 'Description for Item A', unit_price: 100, merchant: merchant)
    item_2 = Item.create!(name: 'Item B', description: 'Description for Item B', unit_price: 50, merchant: merchant)
    invoice = Invoice.create!(customer_id: customer.id, merchant_id: merchant.id, status: 'shipped')
    InvoiceItem.create!(invoice: invoice, item: item_1, quantity: 2) 
    InvoiceItem.create!(invoice: invoice, item: item_2, quantity: 3) 
    total = invoice.calculate_total(merchant.id)
    expected_total = (2 * 100) + (3 * 50)
    expect(total).to eq(expected_total)
  end

  it 'applies dollar discount correctly' do
    merchant = Merchant.create!(name: "Test Merchant")
    coupon = Coupon.create!(name: "hi", code: 'jsdf', merchant: merchant, discount_type: 'dollar', discount_value: 20, active: true)
    customer = Customer.create!(first_name: "Mel", last_name: "Rosa")
    item_1 = Item.create!(name: 'Item A', description: 'Description for Item A', unit_price: 100, merchant: merchant)
    item_2 = Item.create!(name: 'Item B', description: 'Description for Item B', unit_price: 50, merchant: merchant)
    invoice = Invoice.create!(customer_id: customer.id, merchant_id: merchant.id, status: 'shipped', coupon: coupon)
    InvoiceItem.create!(invoice: invoice, item: item_1, quantity: 2) # 2 * 100 = 200
    InvoiceItem.create!(invoice: invoice, item: item_2, quantity: 3) # 3 * 50 = 150
    total = invoice.calculate_total(merchant.id)
    discounted_total = invoice.apply_discount(total, merchant.id)
    expected_total = total - coupon.discount_value 
    expect(discounted_total).to eq(expected_total)
  end

  it 'returns original total if coupon does not belong to the merchant' do
    merchant = Merchant.create!(name: "Test Merchant")
    other_merchant = Merchant.create!(name: "Other Merchant")
    coupon = Coupon.create!(name: "hi", code: 'jsdf', merchant: other_merchant, discount_type: 'dollar', discount_value: 20, active: true)
  
    customer = Customer.create!(first_name: "Mel", last_name: "Rosa")
    item_1 = Item.create!(name: 'Item A', description: 'Description for Item A', unit_price: 100, merchant: merchant)
    item_2 = Item.create!(name: 'Item B', description: 'Description for Item B', unit_price: 50, merchant: merchant)
    invoice = Invoice.create!(customer_id: customer.id, merchant_id: merchant.id, status: 'shipped', coupon: coupon)
    InvoiceItem.create!(invoice: invoice, item: item_1, quantity: 2)
    InvoiceItem.create!(invoice: invoice, item: item_2, quantity: 3)
    total = invoice.calculate_total(merchant.id)
    discounted_total = invoice.apply_discount(total, merchant.id)
    expect(discounted_total).to eq(total)
  end

  it 'returns 0 if total is 0 or less' do
    merchant = Merchant.create!(name: "Test Merchant")
    customer = Customer.create!(first_name: "Mel", last_name: "Rosa")
    coupon = Coupon.create!(name: "hi", code: 'jsdf', merchant: merchant, discount_type: 'dollar', discount_value: 20, active: true)
    invoice = Invoice.create!(customer_id: customer.id, merchant_id: merchant.id, status: 'shipped', coupon: coupon)
    expect(invoice.apply_discount(0, merchant.id)).to eq(0)
    expect(invoice.apply_discount(-10, merchant.id)).to eq(0)
  end
end