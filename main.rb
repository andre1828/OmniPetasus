require 'watir'
require './utils.rb'

username = 'YourUserNameHere'
password = 'Passwordhere'
duolingo_base_url = 'https://www.duolingo.com'
Watir.default_timeout = 10
Selenium::WebDriver::Firefox.driver_path = './geckodriver'
browser = Watir::Browser.new :firefox, headless: false
utils = Utils.new browser, :italian

define_method(:select_image) do
end

define_method(:translate_sentence) do
end

define_method(:start_lesson) do
  browser.span(text: 'Basics 1').click
  case utils.detect_question_type
  when :challenge_select
    select_image
  when :challenge_translate
    translate_sentence
  end
end

browser.goto duolingo_base_url
browser.button(id: 'sign-in-btn').click
browser.text_field(id: 'top_login').set username
browser.text_field(id: 'top_password').set password
browser.button(id: 'login-button').click

# start_lesson
# wait for any skill to be present on the page before proceding
browser.wait_until { browser.span(class: %w[_378Tf _3qO9M _33VdW]).present? }
utils.create_language_db :italian unless utils.exists_language_db :italian
utils.study_language :italian

# browser.close
puts 'DONE'
