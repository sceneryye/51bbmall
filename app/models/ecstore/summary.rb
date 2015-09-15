#encoding:utf-8
class Ecstore::Summary < Ecstore::Base
  self.table_name = "summaries" 
  attr_accessible :histroy_date, :total_member_today, :new_member_today, :new_order_today, :new_order_payed_today
end