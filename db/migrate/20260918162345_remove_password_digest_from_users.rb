class RemovePasswordDigestFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :password_digest, :string
  end
end
