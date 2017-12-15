require 'yaml'
require 'logger'
require 'daemons'

ENVIRONMENT = 'production'
CONFIGURATION = YAML.load_file('config/secrets.yml')[ENVIRONMENT]

CHECK_FREQUENCY = 10#2 * 60   #2 * minutes

LOG_DIRECTORY = "#{File.expand_path File.dirname(__FILE__)}/log"

require './lib/gandi'
require './lib/ddns'

_options = {
  app_name: 'ddns_daemon',
  dir_mode: :script,
  dir: 'tmp',
  log_dir: LOG_DIRECTORY,
  log_output: true,
  monitor: true,
  monitor_interval: 30,
  backtrace: true,
}

Daemons.run_proc('ddns_daemon', _options) do
  LOGGER = Logger.new("#{LOG_DIRECTORY}/#{ENVIRONMENT}.log", 10, 1024000)
  LOGGER.info('Starting daemon...')
  loop do
    LOGGER.info('Starting check...')
    DDNS.update_dns_records
    LOGGER.info('Finished check, going to sleep...')
    sleep(CHECK_FREQUENCY)
  end
end