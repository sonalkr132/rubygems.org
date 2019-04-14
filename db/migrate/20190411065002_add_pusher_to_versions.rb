class AddPusherToVersions < ActiveRecord::Migration[5.2]
  def change
    add_belongs_to :versions, :pusher, foreign_key: {to_table: :users}
  end
end
