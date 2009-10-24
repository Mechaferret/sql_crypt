ActiveRecord::Schema.define(:version => 2) do
  create_table :accounts, :force => true do |t|
    t.column :name, :string
    t.column :balance, :string
    t.column :password, :string
    t.column :acct_number, :string
  end
  
end
