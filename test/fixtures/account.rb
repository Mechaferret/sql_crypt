class Account < ActiveRecord::Base
  sql_encrypted :balance, :key => 'test1'
  sql_encrypted :balance_as_float, :key => 'testf', :converter => :to_f
end