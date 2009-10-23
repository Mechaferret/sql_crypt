require 'test/unit'
require 'rubygems'
require 'active_record'
require 'active_record/fixtures'
require 'active_support'
require 'active_support/test_case'
require 'sql_crypt'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.configurations = {'test' => config[ENV['DB'] || 'mysql']}
ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])

load(File.dirname(__FILE__) + "/schema.rb")

class ActiveSupport::TestCase
  include ActiveRecord::TestFixtures
  self.fixture_path = File.dirname(__FILE__) + "/fixtures"
  self.use_transactional_fixtures = false
  self.use_instantiated_fixtures = false
  fixtures :all
	@@expectations = YAML::load(IO.read(File.dirname(__FILE__) + '/expected_by_db.yml'))

end
