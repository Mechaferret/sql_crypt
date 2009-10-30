require File.dirname(__FILE__) + '/test_helper'
include SQLCrypt
require 'fixtures/account.rb'

class SqlCryptTest < ActiveSupport::TestCase
  
  test "no key raises exception" do
    assert_raise(NoEncryptionKey) {
      Account.sql_encrypted(:balance, {})
    }
  end

  test "each encrypted attribute is added when added in sequence" do
    # :balance is encrypted in model class definition
		assert Account.encrypteds.size==2
		assert Account.encrypteds.first[:name] == :balance
		assert Account.encrypteds.first[:key] == 'test1'
    Account.sql_encrypted(:name, :key => 'test2')
		assert Account.encrypteds.size==3
		assert Account.encrypteds.first[:name] == :balance
		assert Account.encrypteds.first[:key] == 'test1'
		assert Account.encrypteds.last[:name] == :name
		assert Account.encrypteds.last[:key] == 'test2'
  end
  
  test "multiple encrypted attributes can be added" do
    Account.sql_encrypted(:acct_number, :password, :key => 'test4')
		assert Account.encrypteds.size==5
		assert Account.encrypteds[3][:name] == :acct_number
		assert Account.encrypteds[3][:key] == 'test4'
		assert Account.encrypteds.last[:name] == :password
		assert Account.encrypteds.last[:key] == 'test4'
  end
  
  test "encrypted attribute is stored locally" do
		acc = Account.new
		acc.balance = '100'
		assert acc.read_encrypted_value("balance_decrypted")=='100'
  end
  
  test "encrypted attribute is retrieved from the right place" do
		acc = Account.new
		acc.balance = '100'
		assert acc.balance=='100'
		assert acc.balance==acc.read_encrypted_value("balance_decrypted")
  end
  
  test "encrypted attribute is persisted to database" do
		acc = Account.new
		acc.balance = '100'
		acc.save
		fetched_from_db = acc.connection.select_value("select balance from accounts where id=#{acc.id}")
		expected = acc.connection.select_value("select hex(aes_encrypt('100','test1_#{acc.id}'))")
		assert fetched_from_db==expected
  end
  
  test "encrypted attribute is retrieved from database" do
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

  test "encrypted attribute uses specified type" do
		acc = Account.new
		acc.balance_as_float = 150
		acc.save
		acc2 = Account.find(acc.id)
		assert acc2.balance_as_float == 150
	end

end
