class AddTypeToContentMigration < ActiveRecord::Migration
  #tag :predeploy

  def self.up
    add_column :content_migrations, :migration_type, :string
  end

  def self.down
    remove_column :content_migrations, :migration_type
  end
end
