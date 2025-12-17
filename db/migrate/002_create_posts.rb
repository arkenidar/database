class CreatePosts < ActiveRecord::Migration[7.0]
  def change
    create_table :posts do |t|
      t.references :author, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body, null: false
      t.datetime :published_at

      t.timestamps
    end

    add_index :posts, :published_at
  end
end
