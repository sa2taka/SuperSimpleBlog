# frozen_string_literal: true

require 'selenium-webdriver'
require 'webdrivers/chromedriver'
require_relative '../models.rb'

class Scraper
  def self.scrape(top_level, request_url)
    client = Selenium::WebDriver::Remote::Http::Default.new
    client.open_timeout = 120
    driver = Selenium::WebDriver.for :chrome, http_client: client
    driver.manage.timeouts.implicit_wait = 4
    driver.get(top_level.to_s)
    sleep 6

    driver.get(top_level.to_s + "/login")
    element = driver.find_element(:id, 'name')
    element.send_keys 'admin'
    element = driver.find_element(:id, 'password')
    element.send_keys ENV[:password] || 'SuperS1mpleBlog_AdminP@ssw0rd'
    element.submit

    sleep(2)

    begin
      driver.get(request_url)
      sleep 120
    ensure
      driver.quit
    end
  end
end
