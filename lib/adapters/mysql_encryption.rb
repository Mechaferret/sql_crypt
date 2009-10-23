module MySQLEncryption
	def encryption_find(name, key, options={})
		"aes_decrypt(unhex(#{name}), '#{key}') as #{name}"	
	end
	
	def encryption_set(name, key, options={})
		"#{name}=hex(aes_encrypt('#{self.read_attribute("#{name}_decrypted")}', '#{key}'))"	
	end
end