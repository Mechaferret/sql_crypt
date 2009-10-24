class Account < ActiveRecord::Base
  sql_encrypted :balance, :key => 'test1'
end