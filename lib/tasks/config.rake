#encoding:utf-8
namespace :imodec do
	task :config=>:environment do
		Ecstore::Config.where(:key=>"page_title").first_or_initialize(:name=>"网站Title",:value=>"邦邦芒 | 跨境贸易，一键直达").save
		Ecstore::Config.where(:key=>"meta_keywords").first_or_initialize(:name=>"网站Keywords",:value=>"邦邦芒 | 跨境贸易，一键直达").save
		Ecstore::Config.where(:key=>"meta_description").first_or_initialize(:name=>"网站Description",:value=>"邦邦芒 | 跨境贸易，一键直达").save
	end
end