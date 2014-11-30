class AddSharingToSprint < ActiveRecord::Migration
  def change
    add_column :sprints, :sharing, :string, null: false, default: 'none'
    add_index :sprints, :sharing
  end
end
