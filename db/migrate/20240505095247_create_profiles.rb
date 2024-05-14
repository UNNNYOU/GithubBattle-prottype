class CreateProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :profiles do |t|
      t.integer :level, default: 1, null: false
      t.integer :experience_points, default: 0, null: false
      t.integer :week_contributions, default: 0, null: false
      t.integer :temporal_contribution_data, default: 0, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
