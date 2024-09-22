class Coupon < ApplicationRecord
  belongs_to :merchant
  has_many :invoices
  validates :code, uniqueness: { scope: :merchant_id, message: "has already been taken" }
  validates :name, :code, presence: true
  validates :active, inclusion: { in: [true, false] }
  validates :discount_value, presence: true, numericality: { greater_than: 0 }
  validates :discount_type, inclusion: { in: ['dollar', 'percent'], message: "%{value} is not a valid discount type" }
  validate :max_coupons, on: :create

  def self.sorted_by_active(merchant, status)
    if status == 'active'
      merchant.coupons.where(active: true)
    elsif status == 'inactive'
      merchant.coupons.where(active: false)
    else
      merchant.coupons
    end
  end

  def max_coupons
    if merchant && merchant.coupons.where(active: true).count >= 5
      errors.add(:base, "This Merchant already has 5 active coupons.")
    end
  end
end
