require 'active_record'
require 'yaml'
require 'logger'

module Blog
  def self.root
    File.expand_path('../..', __dir__)
  end

  def self.setup_database!(env = 'development')
    config_path = File.join(root, 'config', 'database.yml')
    config = YAML.load_file(config_path, aliases: true)
    
    # Ensure db directory exists
    db_dir = File.join(root, 'db')
    Dir.mkdir(db_dir) unless Dir.exist?(db_dir)
    
    ActiveRecord::Base.establish_connection(config[env])
    ActiveRecord::Base.logger = Logger.new(STDOUT) if env == 'development'
  end

  def self.migrate!
    migrations_path = File.join(root, 'db', 'migrate')
    ActiveRecord::MigrationContext.new(migrations_path).migrate
  end

  def self.load_models!
    models_path = File.join(File.dirname(__FILE__), 'models')
    Dir[File.join(models_path, '*.rb')].sort.each { |f| require f }
  end
end
