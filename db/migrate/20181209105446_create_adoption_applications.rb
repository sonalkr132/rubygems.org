class CreateAdoptionApplications < ActiveRecord::Migration[5.2]
  def change
    create_table :adoption_applications do |t|
      t.references :user, foreign_key: true
      t.references :rubygem, foreign_key: true
      t.integer :approver_id
      t.string :note
      t.integer :status, null: false

      t.timestamps
    end
  end
end
