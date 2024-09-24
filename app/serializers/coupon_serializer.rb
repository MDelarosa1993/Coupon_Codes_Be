class CouponSerializer
  include JSONAPI::Serializer

  attributes :id, :name, :code, :discount_value, :active, :discount_type, :merchant_id
  
  attribute :usage_count do |coupon, params|
    coupon.usage_count
  end
end