class Invoice < ApplicationRecord
  belongs_to :customer
  belongs_to :merchant
  belongs_to :coupon, optional: true
  has_many :invoice_items, dependent: :destroy
  has_many :transactions, dependent: :destroy

  validates :status, inclusion: { in: ["shipped", "packaged", "returned", "pending"] }

  def total_for_merchant(merchant_id)
    total = calculate_total(merchant_id)
    apply_discount(total, merchant_id)
  end

  private

  def calculate_total(merchant_id)
    total = 0
    invoice_items.includes(:item).each do |invoice_item|
      if invoice_item.item&.merchant_id == merchant_id
        item_total = invoice_item.quantity * (invoice_item.item&.unit_price || 0)
        total += item_total
      end
    end
    total
  end

  def apply_discount(total, merchant_id)
    return 0 if total <= 0
    if coupon&.merchant_id == merchant_id
      if coupon.discount_type == 'dollar'
        return 0 if coupon.discount_value >= total
        total -= coupon.discount_value
      elsif coupon.discount_type == 'percent'
        discount_amount = total * (coupon.discount_value / 100.0)
        total -= discount_amount
      end
    end
    total
  end
end