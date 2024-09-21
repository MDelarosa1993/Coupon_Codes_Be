class Coupon < ApplicationRecord
  belongs_to :merchant
  has_many :invoices
  validates :code, uniqueness: { scope: :merchant_id, message: "has already been taken" }
  validates :name, :code, presence: true
  validates :active, inclusion: { in: [true, false] }

  def self.sorted_by_active(merchant, status)
    if status == 'active'
      merchant.coupons.where(active: true)
    elsif status == 'inactive'
      merchant.coupons.where(active: false)
    else
      merchant.coupons
    end
  end
end
