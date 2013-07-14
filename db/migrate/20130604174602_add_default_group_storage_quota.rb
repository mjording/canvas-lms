class AddDefaultGroupStorageQuota < ActiveRecord::Migration
  #tag :predeploy

  def self.up
    add_column :accounts, :default_group_storage_quota, :bigint
  end

  def self.down
    remove_column :accounts, :default_group_storage_quota
  end
end
