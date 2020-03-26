class ForumTables < ActiveRecord::Migration[5.2]
  def change
    create_table :categories do |t|
      t.string :name
      t.string :description
      t.string :status
      t.references :category, index: true, foreign_key: true

      t.timestamps
    end

    create_table :forum_threads do |t|
      t.string :subject
      t.string :status
      t.references :user, required: true, index: true, foreign_key: true
      t.references :category, required: true, index: true, foreign_key: true

      t.timestamps
    end

    create_table :posts do |t|
      t.string :content
      t.references :user, required: true, index: true, foreign_key: true
      t.references :forum_thread, required: true, index: true, foreign_key: true

      t.timestamps
    end

    create_table :votes do |t|
      t.boolean :up
      t.boolean :down

      t.references :user, required: true, foreign_key: true
      t.references :post, foreign_key: true
      t.references :forum_thread, foreign_key: true
    end

  end
end
