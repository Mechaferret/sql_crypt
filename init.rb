require 'sql_crypt'
ActiveRecord::Base.send(:include, SQLCrypt)