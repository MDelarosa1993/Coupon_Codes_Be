class CouponSerializer
  include JSONAPI::Serializer
  attributes :id, :name, :code, :discount_value, :active, :discount_type, :merchant_id
end
