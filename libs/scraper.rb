# frozen_string_literal: true

require 'selenium-webdriver'
require 'webdrivers/chromedriver'
require_relative '../models.rb'

class Scraper
  def self.scrape(top_level, request_url)
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-gpu')
    options.add_argument('--disable-dev-shm-usage')

    client = Selenium::WebDriver::Remote::Http::Default.new
    client.open_timeout = 120
    driver = Selenium::WebDriver.for :chrome, http_client: client, options: options
    driver.manage.timeouts.implicit_wait = 4
    driver.get("http://#{top_level}")
    sleep 6

    driver.get('http://localhost:9292/login')
    element = driver.find_element(:name, 'name')
    element.send_keys 'admin'
    element = driver.find_element(:name, 'password')
    element.send_keys ENV['password'] || 'SuperS1mpleBlog_AdminP@ssw0rd'
    element.submit

    sleep 2

    begin
      driver.get(request_url)
      sleep 120
    ensure
      driver.quit
    end
  end
end
