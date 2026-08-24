class CreateDb < ActiveRecord::Migration[6.0]
  def change
    create_table :users, id: :string do |t|
      t.string :username, null: false
      t.string :password_digest, null: false
      t.timestamps null: false

      t.index :username, unique: true
    end

    create_table :comments, id: :string do |t|
      t.references :predecessor, type: :string, null: true, foreign_key: { to_table: :comments }, index: { unique: true }
      t.references :user, type: :string, null: false
      t.string :thread_id, null: true
      t.string :body, null: false
      t.integer :status, null: false, default: 0
      t.timestamps null: false

      t.index :thread_id, unique: true
    end

    create_table :sessions do |t|
      t.timestamps
    end
  end
end
