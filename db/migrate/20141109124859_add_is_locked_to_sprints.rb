class AddIsLockedToSprints < ActiveRecord::Migration
  def change
	  add_column :sprints, :is_locked, :boolean, null: true, default: false
  end
end
