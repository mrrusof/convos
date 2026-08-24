DEFAULT_ENV = 'production'
DEFAULT_CONFIG_FILE = File.expand_path '../../../config/config.yml', __FILE__

ENV['RACK_ENV'] ||= DEFAULT_ENV
ENV['CONFIG_FILE'] ||= DEFAULT_CONFIG_FILE if ENV['RACK_ENV'] != 'production'

module Convos
  class Configuration
    CONFIG_KEYS = [
      ['CONFIG_FILE', 'The absolute path to the configuration file'],
      ['RACK_ENV', "Rack env (test, development, production) and config file section to read,\ndefaults to production"],
      ['HOST', 'The optional public server origin, including scheme and optional port, without a trailing slash; omit to use relative URLs'],
      ['PORT', 'The server port'],
      ['ACCESS_CONTROL_ALLOW_ORIGIN', 'The allowed origin for widget resources, or * to allow all origins'],
      ['SESSION_SECRET', 'A cryptographically secure random value at least 64 bytes long'],
      ['SESSION_IDLE_TIMEOUT', 'The TTL of every session after each interaction in seconds'],
      ['SESSION_TTL', 'The unconditional TTL of every session in seconds'],
      ['ADMIN_PASSWORD',  'The password of the admin'],
      ['ALTCHA_CHALLENGE_COST', 'The bigger the number, the more computationally costly for the web client'],
      ['ALTCHA_HMAC_SECRET', 'A cryptographically secure random value at least 64 bytes long'],
      ['DB_ADAPTER', 'The database adapter for ActiveRecord (sqlite3 or postgresql)'],
      ['DB_HOST', 'For postgres, the hostname'],
      ['DB_PORT', 'For postgres, the port'],
      ['DB_NAME', 'The database name for postgres, absolute path for sqlite'],
      ['DB_USER', 'For postgres, the username'],
      ['DB_PASSWORD', 'For postgres, the password'],
      ['DB_POOL', 'The size of the conneciton pool'],
      ['DB_TIMEOUT', 'Connection timeouts in milliseconds']
    ]

    OPTIONAL_CONFIG_KEYS = [
      'CONFIG_FILE',
      'HOST',
      'DB_HOST',
      'DB_PORT',
      'DB_USER',
      'DB_PASSWORD',
      'DB_POOL',
      'DB_TIMEOUT'
    ]

    INT_CONFIG_KEYS = [
      'PORT',
      'SESSION_IDLE_TIMEOUT',
      'SESSION_TTL',
      'ALTCHA_CHALLENGE_COST',
      'DB_PORT',
      'DB_TIMEOUT'
    ]

    class << self
      CONFIG_KEYS.each do |k, _|
        attr_accessor k.downcase.to_sym
      end

      def load!
        yaml_config = nil

        begin
          yaml_config = YAML.load_file(ENV['CONFIG_FILE'], aliases: true)[ENV['RACK_ENV']]
        rescue => exn
          puts "WARNING: Cannot load configuration file with path '#{ENV['CONFIG_FILE']}': #{exn}\nUsing configuration given by environment."
        end

        CONFIG_KEYS.each do |k, _|
          v = ENV[k] || (yaml_config && yaml_config[k.downcase])

          abort "FATAL: Configuration parameter #{k} not defined!" if !v.present? && !OPTIONAL_CONFIG_KEYS.member?(k)

          if v.present? && INT_CONFIG_KEYS.member?(k)
            begin
              v = Integer(v)
            rescue
              abort "FATAL: Could not parse value '#{v}' for key '#{k}' as integer."
            end
          end

          self.send("#{k.downcase}=".to_sym, v)
        end

        self.configure_activerecord
      end

      def configure_activerecord
        case self.db_adapter
        when 'postgresql'
          ActiveRecord::Base.configurations = {
            Convos::Configuration.rack_env => {
              adapter: 'postgresql',
              host: self.db_host,
              port: self.db_port,
              database: self.db_name,
              username: self.db_user,
              password: self.db_password,
              pool: self.db_pool,
              timeout: self.db_timeout
            }
          }

        when 'sqlite3'
          ActiveRecord::Base.configurations = {
            Convos::Configuration.rack_env => {
              adapter: 'sqlite3',
              database: self.db_name
            }
          }

        else
          abort "FATAL: Unknown db adapter #{self.db_adapter}"

        end

        ActiveRecord::Base.establish_connection
      end
    end
  end
end
