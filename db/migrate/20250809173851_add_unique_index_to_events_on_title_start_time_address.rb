class AddUniqueIndexToEventsOnTitleStartTimeAddress < ActiveRecord::Migration[8.0]
  def change
    add_index :events, [ :title, :start_time, :address ], unique: true
  end
end
