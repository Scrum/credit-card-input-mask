require "dotenv"
require 'capybara'
require 'capybara/rspec'
require 'selenium-webdriver'
require 'rspec'
require "parallel_tests"
require "rspec/retry"
require 'sauce_whisk'

Dotenv.load

PORT = ENV['PORT'] || 3099
SAUCE_CONNECT_PORT = 4445

Capybara.default_driver = :selenium
Capybara.default_max_wait_time = 20

SauceWhisk.data_center = :US_WEST

$pids = []

def spawn_until_port(cmd, port)
  `lsof -i :#{port}`
  if $? != 0
    puts "[STARTING] #{cmd} on #{port}"
    $pids.push spawn(cmd, :out => "/dev/null")
    wait_port(port)
  end
  puts "[RUNNING] #{cmd} on #{port}"
end

def wait_port(port)
  loop do
    `lsof -i :#{port}`
    sleep 2
    break if $? == 0
  end
end
RSpec.configure do |config|
  config.include Capybara::DSL
  config.include Capybara::RSpecMatchers

  config.verbose_retry = true
  config.around(:each) do |c|
    c.run_with_retry(retry: 2)
  end

  if ParallelTests.first_process?
    config.before(:suite) do
      spawn_until_port("npm run development", PORT)
      spawn_until_port("npm run sauceconnect", SAUCE_CONNECT_PORT)
    end

    config.after(:suite) do
      ParallelTests.wait_for_other_processes_to_finish
      $pids.each do |pid|
        Process.kill("INT", pid)
      end
    end
  else
    config.before(:suite) do
      wait_port PORT
      wait_port SAUCE_CONNECT_PORT
    end
  end

  config.before(:each) do |test|
    Capybara.register_driver :sauce do |app|
      opt = platform(test.full_description)

      caps = Selenium::WebDriver::Remote::Capabilities.send(opt.delete(:browser_name).to_sym, opt)

      caps['tunnel-identifier'] = ENV['TRAVIS_JOB_NUMBER'] if ENV['TRAVIS_JOB_NUMBER']
      url = 'https://ondemand.saucelabs.com:443/wd/hub'

      Capybara::Selenium::Driver.new(app, browser: :remote,
                                          url: url,
                                          desired_capabilities: caps)
    end
    Capybara.current_driver = :sauce
  end

  config.after(:each) do |test|
    session_id = Capybara.current_session.driver.browser.session_id
    SauceWhisk::Jobs.change_status(session_id, !test.exception)
    Capybara.current_session.quit
  end

  def platform(name)
    case ENV['PLATFORM']
    when 'windows_10_edge'
      {platform_name: 'Windows 10',
       browser_name: 'edge',
       browser_version: '18.17763'}.merge(sauce_w3c(name))
    when 'windows_8_ie'
      {platform: 'Windows 8.1',
       browser_name: 'ie',
       version: '11.0'}.merge(sauce_w3c(name))
    when 'windows_10_chrome'
      # This is for running Chrome with w3c which is not yet the default
      {platform_name: 'Windows 10',
       browser_name: 'chrome',
       "goog:chromeOptions": {w3c: true}, browser_version: '65.0'}.merge(sauce_w3c(name))
    when 'mac_mojave_safari'
      {platform_name: 'macOS 10.14',
       browser_name: 'safari',
       browser_version: '12.0'}.merge(sauce_w3c(name))
    when 'windows_7_ff'
      {platform_name: 'Windows 7',
       browser_name: 'firefox',
       browser_version: '60.0'}.merge(sauce_w3c(name))
    else
      # Always specify a default;
      # this doesn't force Chrome to w3c
      {platform: 'macOS 10.12',
       browser_name: 'chrome',
       version: '65.0'}.merge(sauce_oss(name))
    end
  end

  def sauce_w3c(name)
    {'sauce:options' => {name: name,
                         build: build_name,
                         username: ENV['SAUCE_USERNAME'],
                         access_key: ENV['SAUCE_ACCESS_KEY'],
                         iedriver_version: '3.141.59',
                         selenium_version: '3.141.59'}}
  end

  def sauce_oss(name)
    {name: name,
     build: build_name,
     username: ENV['SAUCE_USERNAME'],
     access_key: ENV['SAUCE_ACCESS_KEY'],
     selenium_version: '3.141.59'}
  end

  #
  # Note that this build name is specifically for Travis CI execution
  # Most CI tools have ENV variables that can be structured to provide useful build names
  #
  def build_name
    if ENV['TRAVIS_REPO_SLUG']
      "#{ENV['TRAVIS_REPO_SLUG'][%r{[^/]+$}]}: #{ENV['TRAVIS_JOB_NUMBER']}"
    elsif ENV['SAUCE_START_TIME']
      ENV['SAUCE_START_TIME']
    else
      "Restricted Input: Local-#{Time.now.to_i}"
    end
  end
end
