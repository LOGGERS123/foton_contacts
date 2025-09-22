class CreateContactRoles < ActiveRecord::Migration[5.2]
  def change
    create_table :contact_roles do |t|
      t.references :contact, null: false, foreign_key: true # pessoa
      t.references :company, null: false, foreign_key: { to_table: :contacts }
      t.string :position
      t.integer :status, default: 0 # 0: active, 1: inactive, 2: discontinued
      t.date :start_date
      t.date :end_date
      t.text :notes
      t.timestamps

      t.index [:contact_id, :company_id, :position], unique: true
      t.index :status
    end
  end
end