module SQLCrypt
	Dir[File.dirname(__FILE__) + '/adapters/*.rb'].each{|g| require g}  

	class NoEncryptionKey < Exception #:nodoc:
  end
	
	class NoAdapterFound < Exception #:nodoc:
  end
	
	def self.included(base)
    base.extend ClassMethods
  end

	module ClassMethods
		def initialize_sql_crypt
			already_done = (!self.encrypteds.empty? rescue false)
			return if already_done
      include InstanceMethods
			begin
				include "#{self.connection.adapter_name}Encryption".constantize
			rescue
				raise NoAdapterFound.new(self.connection.adapter_name)
			end
			define_method (:after_find) { } unless method_defined?(:after_find)
			after_find :find_encrypted
			after_save :save_encrypted
			cattr_accessor :encrypteds
			self.encrypteds = Array.new
			@@sql_crypt_initialized = true
		end
		
		def sql_encrypted(*args)
			raise NoEncryptionKey unless args.last[:key]			
			self.initialize_sql_crypt
			secret_key = args.last[:key]
			args.delete args.last
			
			args.each { |name| 
  			self.encrypteds << {:name=>name, :key=>secret_key}
        module_eval <<-"end_eval"
          def #{name}
  					self.read_attribute("#{name}_decrypted")
  				end

          def #{name}=(value)
  					self.write_attribute("#{name}_decrypted", value)
          end
        end_eval
      }
		end
	end
	
	module InstanceMethods
	  def find_encrypted
			encrypted_find = self.class.encrypteds.collect{|y| encryption_find(y[:name], y[:key])}.join(',')
			puts "finding with #{encrypted_find}"
	    encrypteds = connection.select_one("select #{encrypted_find} from #{self.class.table_name} where #{self.class.primary_key}=#{self.id}")
	    encrypteds.each {|k, v| self.write_attribute("#{k}_decrypted", v) }
	  end

	  def save_encrypted
			encrypted_save = self.class.encrypteds.collect{|y| encryption_set(y[:name], y[:key])}.join(',')
			puts "saving with #{encrypted_save}"
	    connection.execute("update #{self.class.table_name} set #{encrypted_save} where #{self.class.primary_key}=#{self.id}")
	  end
	end
	
end