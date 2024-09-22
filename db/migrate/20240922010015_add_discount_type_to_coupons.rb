class AddDiscountTypeToCoupons < ActiveRecord::Migration[7.1]
  def change
    add_column :coupons, :discount_type, :string
  end
end
