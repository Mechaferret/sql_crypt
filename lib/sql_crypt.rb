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
      include InstanceMethods::SQLCryptMethods
			begin
				include "#{self.connection.adapter_name}Encryption".constantize
			rescue
				raise NoAdapterFound.new(self.connection.adapter_name)
			end
			define_method (:after_find) { } unless method_defined?(:after_find)
			after_find :find_encrypted
			after_save :save_encrypted
			cattr_accessor :encrypteds
			cattr_accessor :converters
			self.encrypteds = Array.new
			self.converters = Hash.new
			@@sql_crypt_initialized = true
		end
		
		def sql_encrypted(*args)
			raise NoEncryptionKey unless args.last[:key]			
			self.initialize_sql_crypt
			secret_key = args.last[:key]
			decrypted_converter = args.last[:converter]
			args.delete args.last
			
			args.each { |name| 
  			self.encrypteds << {:name=>name, :key=>secret_key}
				self.converters[name] = decrypted_converter
        module_eval <<-"end_eval"
          def #{name}
  					self.read_encrypted_value("#{name}_decrypted")
  				end

          def #{name}=(value)
  					self.write_encrypted_value("#{name}_decrypted", value)
          end
        end_eval
      }
		end
	end
	
	module InstanceMethods
	  def find_encrypted
			encrypted_find = self.class.encrypteds.collect{|y| encryption_find(y[:name], y[:key])}.join(',')
	    encrypteds = connection.select_one("select #{encrypted_find} from #{self.class.table_name} where #{self.class.primary_key}=#{self.id}")
	    encrypteds.each {|k, v| write_encrypted_value("#{k}_decrypted", convert(k, v), false) }
	  end

	  def save_encrypted
			encrypted_save = self.class.encrypteds.collect{|y| encryption_set(y[:name], y[:key]) if encrypted_changed?(y[:name])}.delete_if{|c|c.blank?}.join(',')
			return if encrypted_save.blank? # no changes to save
	    connection.execute("update #{self.class.table_name} set #{encrypted_save} where #{self.class.primary_key}=#{self.id}")
	  end
	
		def convert(name, value)
			converter = self.class.converters[name.to_sym]
			converter.nil? ? value : value.send(converter)		
		end
		
		module SQLCryptMethods
			def read_encrypted_value(name)
				@sql_crypt_data[name] rescue nil
			end
			
			def write_encrypted_value(name, value, check_changed=true)
				@sql_crypt_data = Hash.new if @sql_crypt_data.nil?
				@sql_crypt_changed = Hash.new if @sql_crypt_changed.nil?
				if check_changed
  				old_value = encrypted_orig_value(name)
  				if value!=old_value
    				@sql_crypt_changed[name] ||= Hash.new
    				@sql_crypt_changed[name][:old] = old_value
    				@sql_crypt_changed[name][:new] = value
    			else
    			  @sql_crypt_changed[name] = nil
  				end
  			end
				@sql_crypt_data[name] = value
			end
			
			def encrypted_orig_value(name)
			  @sql_crypt_changed[name][:old] rescue read_encrypted_value(name)
			end
			
			def encrypted_changed?(name)
			  @sql_crypt_changed["#{name}_decrypted"]
			end
			
			def enc_chg
			  @sql_crypt_changed
			end
		end
	end
	
end