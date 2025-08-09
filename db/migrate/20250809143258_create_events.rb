class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :title
      t.text :description
      t.datetime :start_time
      t.datetime :end_time
      t.string :venue
      t.string :address
      t.float :latitude
      t.float :longitude
      t.string :url
      t.string :image_url

      t.timestamps
    end
  end
end
