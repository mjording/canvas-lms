class AddGroupLimitToGroupCategory < ActiveRecord::Migration
  #tag :predeploy

  def self.up
    add_column :group_categories, :group_limit, :integer
  end

  def self.down
    remove_column :group_categories, :group_limit
  end
end
