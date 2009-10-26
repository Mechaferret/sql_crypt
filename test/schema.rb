ActiveRecord::Schema.define(:version => 3) do
  create_table :accounts, :force => true do |t|
    t.column :name, :string
    t.column :balance, :string
    t.column :password, :string
    t.column :acct_number, :string
		t.column :balance_as_float, :string
  end
  
end
