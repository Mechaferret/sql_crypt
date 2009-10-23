require File.dirname(__FILE__) + '/test_helper'
include SQLCrypt
require 'fixtures/account.rb'

class SqlCryptTest < ActiveSupport::TestCase
  test "no key raises exception" do
    assert_raise(NoEncryptionKey) {
      Account.sql_encrypted(:balance, {})
    }
  end

  test "each encrypted attribute is added" do
    Account.sql_encrypted(:balance, :key => 'test1')
		assert Account.encrypteds.size==1
		assert Account.encrypteds.first[:name] == :balance
		assert Account.encrypteds.first[:key] == 'test1'
    Account.sql_encrypted(:name, :key => 'test2')
		assert Account.encrypteds.size==2
		assert Account.encrypteds.first[:name] == :balance
		assert Account.encrypteds.first[:key] == 'test1'
		assert Account.encrypteds.last[:name] == :name
		assert Account.encrypteds.last[:key] == 'test2'
  end
  
  test "encrypted attribute is stored locally" do
    Account.sql_encrypted(:balance, :key => 'test1')
		acc = Account.new
		acc.balance = '100'
		assert acc.read_attribute("balance_decrypted")=='100'
  end
  
  test "encrypted attribute is retrieved from the right place" do
    Account.sql_encrypted(:balance, :key => 'test1')
		acc = Account.new
		acc.balance = '100'
		assert acc.balance=='100'
		assert acc.balance==acc.read_attribute("balance_decrypted")
  end
  
  test "encrypted attribute is persisted to database" do
    Account.sql_encrypted(:balance, :key => 'test1')
		acc = Account.new
		acc.balance = '100'
		acc.save
		fetched_from_db = acc.connection.select_value("select balance from accounts where id=#{acc.id}")
		assert fetched_from_db==@@expectations[acc.connection.adapter_name]["account-100"]
  end
  
  test "encrypted attribute is retrieved from database" do
    Account.sql_encrypted(:balance, :key => 'test1')
		acc = Account.new
		acc.balance = '100'
		acc.save
		acc2 = Account.find(acc.id)
		assert acc2.balance == '100'
		# Do an update too
		acc.balance = '220'
		acc.save
		acc3 = Account.find(acc.id)
		assert acc3.balance == '220'
  end
end
