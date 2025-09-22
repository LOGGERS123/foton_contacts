class CreateContactGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :contact_groups do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :is_private, default: false
      t.references :author, foreign_key: { to_table: :users }
      t.references :project
      t.boolean :is_system, default: false
      t.timestamps

      t.index :name
      t.index :is_private
      t.index :is_system
    end
  end
end