class FixBulkMessageAttachments < ActiveRecord::Migration
  #tag :postdeploy
  #self.transactional = false

  def self.up
    DataFixup::FixBulkMessageAttachments.send_later_if_production(:run)
  end

  def self.down
    # The migration is non-destructive and only adds missing attachment associations
  end
end
