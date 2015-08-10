class Imodec::MembersCase < ActiveRecord::Base
  self.table_name = "members_cases"
 # attr_accessible :name, :description,:parent_id

 # self.accessible_all_columns

  belongs_to :controller,:class_name=>"Ecstore::Member",:foreign_key=>"member_id"

end