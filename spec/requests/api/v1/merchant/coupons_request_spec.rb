require 'rails_helper'

RSpec.describe "Coupons", type: :request do
  describe "GET /show" do
    it 'return one coupon by id' do 
      merchant = Merchant.create!(id: 1, name: "Sample Merchant")
      coupon = Coupon.create!(name: "Buy One Get One 50", code: "BOGO50", discount_value: 50, active: true, discount_type: 'percent', merchant_id: merchant.id)

      get "/api/v1/merchants/#{merchant.id}/coupons/#{coupon.id}"

      expect(response).to have_http_status(200)
      expect(response).to be_successful

      json_response = JSON.parse(response.body)
      
      expect(json_response['data']['id']).to eq(coupon.id.to_s)
      expect(json_response['data']['type']).to eq('coupon')
      expect(json_response['data']['attributes']['name']).to eq(coupon.name)
      expect(json_response['data']['attributes']['code']).to eq(coupon.code)
      expect(json_response['data']['attributes']['discount_value']).to be_a(String)
      expect(json_response['data']['attributes']['active']).to eq(coupon.active?)
      expect(json_response['data']['attributes']['merchant_id']).to eq(coupon.merchant_id)
    end

    it 'returns a 404 when a coupon does not exist' do
      merchant = Merchant.create!(id: 1, name: "Sample Merchant")

      get "/api/v1/merchants/#{merchant.id}/coupons/9999"

      expect(response).to have_http_status(404)
      json_response = JSON.parse(response.body)
      
      expect(json_response['message']).to include("Your query could not be completed")
      expect(json_response['errors']).to include("Couldn't find Coupon with 'id'=9999")
    end
  end

  describe 'GET/index' do
    it 'returns all coupons for certain merchant id' do 
      merchant = Merchant.create!(id: 1, name: "Sample Merchant")
      Coupon.create!(name: "Buy One Get One 50", code: "BOGO50", discount_value: 50, active: true, discount_type: 'percent', merchant_id: merchant.id)
      Coupon.create!(name: "Buy One Get One 40", code: "BOGO40", discount_value: 40, active: true, discount_type: 'percent', merchant_id: merchant.id)
      Coupon.create!(name: "Buy One Get One 30", code: "BOGO30", discount_value: 30, active: false, discount_type: 'percent', merchant_id: merchant.id)
      Coupon.create!(name: "Buy One Get One 20", code: "BOGO20", discount_value: 20, active: false, discount_type: 'percent', merchant_id: merchant.id)

      get "/api/v1/merchants/#{merchant.id}/coupons"

      expect(response).to be_successful

      json_response = JSON.parse(response.body, symbolize_names: true)[:data]
      expect(json_response.size).to eq(4)
      
      json_response.each do |coupon|
        expect(coupon[:id]).to be_a(String)
        expect(coupon[:type]).to eq('coupon')
        expect(coupon[:attributes]).to have_key(:id)
        expect(coupon[:attributes][:id]).to be_an(Integer)
        expect(coupon[:attributes][:name]).to be_a(String)
        expect(coupon[:attributes][:code]).to be_a(String)
        expect(coupon[:attributes][:discount_value]).to be_a(String)
        expect([true, false]).to include(coupon[:attributes][:active])
        expect(coupon[:attributes][:merchant_id]).to be_an(Integer)
      end
    end

      it 'returns all coupons sorted by their active key if its active' do 
        merchant = Merchant.create!(id: 1, name: "Sample Merchant")
        Coupon.create!(name: "Buy One Get One 50", code: "BOGO50", discount_value: 50, active: true, discount_type: 'percent', merchant_id: merchant.id)
        Coupon.create!(name: "Buy One Get One 20", code: "BOGO20", discount_value: 20, active: false, discount_type: 'percent', merchant_id: merchant.id)

        get "/api/v1/merchants/#{merchant.id}/coupons?sort_by=active"

        expect(response).to be_successful
        active_coupon = JSON.parse(response.body, symbolize_names: true)
        
        expect(active_coupon[:data].first[:id].to_i).to be_an(Integer)
        expect(active_coupon[:data].first[:type]).to eq('coupon')
        expect(active_coupon[:data].first[:attributes][:name]).to eq("Buy One Get One 50")
        expect(active_coupon[:data].first[:attributes][:code]).to eq("BOGO50")
        expect(active_coupon[:data].first[:attributes][:discount_value]).to be_a(String)
        expect(active_coupon[:data].first[:attributes][:active]).to eq(true)
        expect(active_coupon[:data].first[:attributes][:merchant_id]).to eq(merchant.id)
      end

      it 'returns all coupons sorted by their active key if its inactive' do
        merchant = Merchant.create!(id: 1, name: "Sample Merchant")
        Coupon.create!(name: "Buy One Get One 50", code: "BOGO50", discount_value: 50, discount_type: 'dollar', active: true, merchant_id: merchant.id)
        Coupon.create!(name: "Buy One Get One 20", code: "BOGO20", discount_value: 20, active: false, discount_type: 'percent', merchant_id: merchant.id)

        get "/api/v1/merchants/#{merchant.id}/coupons?sort_by=inactive"

        expect(response).to be_successful
        active_coupon = JSON.parse(response.body, symbolize_names: true)
        
        expect(active_coupon[:data].first[:id].to_i).to be_an(Integer)
        expect(active_coupon[:data].first[:type]).to eq('coupon')
        expect(active_coupon[:data].first[:attributes][:name]).to eq("Buy One Get One 20")
        expect(active_coupon[:data].first[:attributes][:code]).to eq("BOGO20")
        expect(active_coupon[:data].first[:attributes][:discount_value]).to be_a(String)
        expect(active_coupon[:data].first[:attributes][:active]).to eq(false)
        expect(active_coupon[:data].first[:attributes][:merchant_id]).to eq(merchant.id)
      end
  
      it 'returns an error is there is no merchant with that id' do 
        merchant = Merchant.create!(id: 1, name: "Sample Merchant")
        Coupon.create!(name: "Buy One Get One 50", code: "BOGO50", discount_value: 50, active: true, discount_type: 'percent', merchant_id: merchant.id)
        Coupon.create!(name: "Buy One Get One 40", code: "BOGO40", discount_value: 40, active: true, discount_type: 'percent', merchant_id: merchant.id)
        Coupon.create!(name: "Buy One Get One 30", code: "BOGO30", discount_value: 30, active: false, discount_type: 'percent', merchant_id: merchant.id)
        Coupon.create!(name: "Buy One Get One 20", code: "BOGO20", discount_value: 20, active: false, discount_type: 'percent', merchant_id: merchant.id)

        get "/api/v1/merchants/9999/coupons"
        
        expect(response).to have_http_status(404)
        
        json_response = JSON.parse(response.body)
      
        expect(json_response['message']).to include("Your query could not be completed")
        expect(json_response['errors']).to include("Couldn't find Merchant with 'id'=9999")
      end
    end

    describe 'POST' do 
      it 'creates a new coupon' do 
        merchant = Merchant.create!(name: "Sample Merchant")
        coupon_params = { name: "Buy One Get One 50", code: "BOGO50", discount_value: 50, discount_type: 'percent', active: true }

        post "/api/v1/merchants/#{merchant.id}/coupons", params: { coupon: coupon_params }
        
        expect(response).to have_http_status(201)

        created_coupon = Coupon.last
        expect(created_coupon.name).to eq("Buy One Get One 50")
        expect(created_coupon.code).to eq("BOGO50")
        expect(created_coupon.discount_value).to eq(50)
        expect(created_coupon.active).to be_truthy
        expect(created_coupon.merchant_id).to eq(merchant.id)
      end

      it 'fails to create new coupon' do
        merchant = Merchant.create!(name: "Sample Merchant")
        invalid_coupon_params = { name: "", code: "", discount_value: -10, discount_type: 'percent', active: true } # Invalid values
      
        post "/api/v1/merchants/#{merchant.id}/coupons", params: { coupon: invalid_coupon_params }
      
        expect(response).to have_http_status(:unprocessable_entity)
      
        expect(Coupon.count).to eq(0)
      
        error_response = JSON.parse(response.body)
        expect(error_response).to include('errors')
      end

      it 'returns an error if merchant already has 5 active coupons' do 
        merchant = Merchant.create!(name: "Sample Merchant")
        Coupon.create!(name: "Buy One Get One 50", code: "BOGO50", discount_value: 50, active: true, discount_type: 'percent', merchant_id: merchant.id)
        Coupon.create!(name: "Buy One Get One 40", code: "BOGO40", discount_value: 40, active: true, discount_type: 'percent', merchant_id: merchant.id)
        Coupon.create!(name: "Buy One Get One 30", code: "BOGO30", discount_value: 30, active: true, discount_type: 'percent', merchant_id: merchant.id)
        Coupon.create!(name: "Buy One Get One 20", code: "BOGO20", discount_value: 20, active: true, discount_type: 'percent', merchant_id: merchant.id)
        Coupon.create!(name: "Buy One Get One 10", code: "BOGO10", discount_value: 10, active: true, discount_type: 'percent', merchant_id: merchant.id)

        new_coupon_params = { name: "Extra Coupon", code: "EXTRA", discount_value: 15, discount_type: 'percent', active: true }

        post "/api/v1/merchants/#{merchant.id}/coupons", params: { coupon: new_coupon_params }
        
        expect(response).to have_http_status(422)

        error_message = JSON.parse(response.body, symbolize_names: true)
        

        expect(error_message[:message]).to eq("Your query could not be completed")
        expect(error_message[:errors]).to include("Validation failed: This Merchant already has 5 active coupons.")
      end

      it 'fails validation if coupon code entered is not unique' do
        merchant = Merchant.create!(name: "Sample Merchant")
        Coupon.create!(name: "Existing Coupon", code: "UNIQUECODE", discount_value: 10, discount_type: 'percent', active: true, merchant: merchant)
      
        new_coupon_params = { name: "Duplicate Coupon", code: "UNIQUECODE", discount_value: 15, discount_type: 'percent', active: true }
      
        post "/api/v1/merchants/#{merchant.id}/coupons", params: { coupon: new_coupon_params }
      
        expect(response).to have_http_status(422)
      
        error_message = JSON.parse(response.body, symbolize_names: true)
      
        expect(error_message[:message]).to eq("Your query could not be completed")
        expect(error_message[:errors]).to include("Validation failed: Code has already been taken")
      end
    end

    describe 'PATCH' do 
      it 'updates a coupon from active to inactive' do 
        merchant = Merchant.create!(name: "Sample Merchant")
        coupon = Coupon.create!(name: "Buy One Get One 50", code: "BOGO50", discount_value: 50, active: true, discount_type: 'percent', merchant_id: merchant.id)
        coupon_params = { name: "Buy One Get One 50", code: "BOGO50", discount_value: 50, active: false, merchant_id: merchant.id}

        patch "/api/v1/merchants/#{merchant.id}/coupons//#{coupon.id}", params: { coupon: coupon_params }
        
        expect(response).to have_http_status(200)

        updated_coupon = JSON.parse(response.body, symbolize_names: true)
        
        expect(updated_coupon).to have_key(:data)
        expect(updated_coupon[:data]).to have_key(:id)
        expect(updated_coupon[:data][:id]).to be_a(String)
        expect(updated_coupon[:data][:type]).to eq('coupon')
        expect(updated_coupon[:data]).to have_key(:attributes)
        expect(updated_coupon[:data][:attributes]).to have_key(:id)
        expect(updated_coupon[:data][:attributes][:id]).to be_an(Integer)
        expect(updated_coupon[:data][:attributes]).to have_key(:name)
        expect(updated_coupon[:data][:attributes][:name]).to be_a(String)
        expect(updated_coupon[:data][:attributes]).to have_key(:code)
        expect(updated_coupon[:data][:attributes][:code]).to be_a(String)
        expect(updated_coupon[:data][:attributes]).to have_key(:discount_value)
        expect(updated_coupon[:data][:attributes][:discount_value]).to be_a(String)
        expect(updated_coupon[:data][:attributes]).to have_key(:active)
        expect(updated_coupon[:data][:attributes][:active]).to eq(false)
        expect(updated_coupon[:data][:attributes]).to have_key(:merchant_id)
        expect(updated_coupon[:data][:attributes][:merchant_id]).to be_an(Integer)
      end
      it 'does not allow deactivation if there are pending invoices' do
        merchant = Merchant.create!(name: "Sample Merchant")
        coupon = Coupon.create!(name: "Seasonal Discount", code: "SEASONAL", discount_value: 20, active: true, discount_type: 'percent', merchant: merchant)
        
        customer = Customer.create!(first_name: "Mel", last_name: "Rose")
        Invoice.create!(merchant: merchant, customer: customer, coupon: coupon, status: "pending")
        
        patch "/api/v1/merchants/#{merchant.id}/coupons/#{coupon.id}", params: { coupon: { active: false } }
        
        expect(response).to have_http_status(:unprocessable_entity)
        error_message = JSON.parse(response.body, symbolize_names: true)
        
        expect(error_message[:message]).to include("Your query could not be completed")
        expect(error_message[:errors]).to include("Validation failed: Cannot deactivate coupon with pending invoices.")
      end
    end
end