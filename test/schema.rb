ActiveRecord::Schema.define(:version => 1) do
  create_table :accounts, :force => true do |t|
    t.column :name, :string
    t.column :balance, :string
  end
  
end
