require "rails_helper"

RSpec.describe "Merchant invoices endpoints" do
  before :each do
    @merchant2 = create(:merchant)
    @merchant1 = create(:merchant)

    @customer1 = create(:customer)
    @customer2 = create(:customer)

    @invoice1 = Invoice.create!(customer: @customer1, merchant: @merchant1, status: "packaged")
    create_list(:invoice, 3, merchant_id: @merchant1.id, customer_id: @customer1.id) # shipped by default
    @invoice2 = Invoice.create!(customer: @customer1, merchant: @merchant2, status: "shipped")
  end

  it "should return all invoices for a given merchant based on status param" do
    get "/api/v1/merchants/#{@merchant1.id}/invoices?status=packaged"

    json = JSON.parse(response.body, symbolize_names: true)

    expect(response).to be_successful
    expect(json[:data].count).to eq(1)
    expect(json[:data][0][:id]).to eq(@invoice1.id.to_s)
    expect(json[:data][0][:type]).to eq("invoice")
    expect(json[:data][0][:attributes][:customer_id]).to eq(@customer1.id)
    expect(json[:data][0][:attributes][:merchant_id]).to eq(@merchant1.id)
    expect(json[:data][0][:attributes][:status]).to eq("packaged")
  end

  it "should get multiple invoices if they exist for a given merchant and status param" do
    get "/api/v1/merchants/#{@merchant1.id}/invoices?status=shipped"

    json = JSON.parse(response.body, symbolize_names: true)

    expect(response).to be_successful
    expect(json[:data].count).to eq(3)
  end

  it "should only get invoices for merchant given" do
    get "/api/v1/merchants/#{@merchant2.id}/invoices?status=shipped"

    json = JSON.parse(response.body, symbolize_names: true)

    expect(response).to be_successful
    expect(json[:data].count).to eq(1)
    expect(json[:data][0][:id]).to eq(@invoice2.id.to_s)
  end

  it "should return 404 and error message when merchant is not found" do
    get "/api/v1/merchants/100000/customers"

    json = JSON.parse(response.body, symbolize_names: true)

    expect(response).to have_http_status(:not_found)
    expect(json[:message]).to eq("Your query could not be completed")
    expect(json[:errors]).to be_a Array
    expect(json[:errors].first).to eq("Couldn't find Merchant with 'id'=100000")
  end

  it 'returns all merchant invoices and includes the coupon id if used' do 
    merchant = Merchant.create!(id: 1, name: "Sample Merchant")
    customer_1 = Customer.create!(first_name: "Mel", last_name: "Rose")
    customer_2 = Customer.create!(first_name: "Saul", last_name: "Rose")
    coupon = Coupon.create!(name: "Buy One Get One 50", code: "BOGO50", discount_value: 50, active: true, discount_type: 'percent', merchant_id: merchant.id)
    Invoice.create!(merchant_id: 1, customer_id: customer_1.id, coupon_id: coupon.id, status: "shipped")
    Invoice.create!(merchant_id: 1, customer_id: customer_2.id, coupon_id: nil, status: "returned")
    Invoice.create!(merchant_id: 1, customer_id: customer_1.id, coupon_id: coupon.id, status: "shipped")
    Invoice.create!(merchant_id: 1, customer_id: customer_1.id, coupon_id: coupon.id, status: "shipped")

    get "/api/v1/merchants/#{merchant.id}/invoices"

    expect(response).to be_successful
    
    invoices = JSON.parse(response.body, symbolize_names: true)[:data]
    expect(invoices.size).to eq(4)
    
    invoices.each do |invoice|
      expect(invoice[:id]).to be_a(String)
      expect(invoice[:type]).to eq("invoice")  
      expect(invoice[:attributes][:merchant_id]).to be_an(Integer)  
      expect(invoice[:attributes][:customer_id]).to be_an(Integer)  
      expect([nil, coupon.id]).to include(invoice[:attributes][:coupon_id])      
      expect(invoice[:attributes][:status]).to be_a(String)  
    end
  end
end