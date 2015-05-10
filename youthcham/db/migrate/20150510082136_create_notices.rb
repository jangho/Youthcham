class CreateNotices < ActiveRecord::Migration
  def change
    create_table :notices do |t|
      t.string :title
      t.string :sub_title
      t.text :body
      t.string :image_src
      t.integer :hits

      t.timestamps null: false
    end
  end
end
