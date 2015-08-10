#encoding:utf-8
class Ecstore::DiscountCode < Ecstore::Base
  self.table_name = "sdb_b2c_discount_codes"
  self.primary_key = 'code'

  
  self.accessible_all_columns
  belongs_to :user,:foreign_key=>"member_id"

  has_many :users, :foreign_key=>"discount_code"
  has_many :orders, :foreign_key=>"discout_code"
end