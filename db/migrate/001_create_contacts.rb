class CreateContacts < ActiveRecord::Migration[5.2]
  def change
    create_table :contacts do |t|
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.text :address
      t.string :contact_type, null: false
      t.string :status, default: 'active'
      t.boolean :is_private, default: false
      t.references :author, foreign_key: { to_table: :users }
      t.references :project
      t.references :user
      t.text :description
      t.timestamps

      t.index :name
      t.index :contact_type
      t.index :status
      t.index :is_private
    end
  end
end