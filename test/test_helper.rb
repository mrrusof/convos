# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'
ENV['CONFIG_FILE'] = File.expand_path '../../config/config.yml', __FILE__

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'convos'

require 'minitest/autorun'
require 'capybara/minitest'
require 'selenium-webdriver'
require 'faker'
require 'base64'

Capybara.configure do |config|
  config.app = Convos::Api
  config.default_driver = :selenium_chrome
end

class Minitest::Test
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end
