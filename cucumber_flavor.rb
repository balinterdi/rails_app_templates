# Sets up a Rails app with Cucumber (Rspec, Webrat, Factorygirl),
# Authlogic and Haml
# Also copies polished(?) config files and some basic step definitions

gem "rspec", :version => ">= 1.2.6", :lib => 'spec'
gem "rspec-rails", :version => ">= 1.2.6", :lib => 'spec/rails'
gem "cucumber", :version => ">= 0.3.9"
gem "thoughtbot-factory_girl", :lib => "factory_girl", :source => "http://gems.github.com"
gem "webrat", :version => ">= 0.4.3"
gem "Selenium", :version => ">= 1.1.14", :lib => 'selenium'
gem "selenium-client", :version => ">= 1.2.14", :lib => 'selenium'
gem "bmabey-database_cleaner", :version => ">= 0.1.2", :lib => "database_cleaner"
gem "haml"
gem "authlogic"

rake "gems:unpack:dependencies"
rake "gems:build"

generate(:rspec)
generate(:cucumber)

file "cucumber.yml", <<-EOS
default: -r features/support/env.rb -r features/support/plain.rb -r features/step_definitions --tags ~@enhanced features/
enhanced: -r features/support/env.rb -r features/support/enhanced.rb -r features/step_definitions --tags @enhanced features/
current: -r features/support/env.rb -r features/support/plain.rb -r features/step_definitions --tags current features/
EOS

file ".gitignore", <<-EOS
.DS_Store  
log/*.log  
tmp/**/*  
config/database.yml  
db/*.sqlite3  
EOS

file "features/support/env.rb", <<-EOS
# Sets up the Rails environment for Cucumber
ENV["RAILS_ENV"] ||= "test"
dir = File.expand_path(File.dirname(__FILE__))
require File.join(dir, '..', '..', 'config', 'environment')

require 'cucumber/rails/world'
require 'cucumber/formatter/unicode' # Comment out this line if you don't want Cucumber Unicode support
Cucumber::Rails.bypass_rescue # Comment out this line if you want Rails own error handling 
                              # (e.g. rescue_action_in_public / rescue_responses / rescue_from)

require 'webrat'

Webrat.configure do |config|
  config.mode = :rails
end

require 'cucumber/rails/rspec'
require 'webrat/core/matchers'

require 'factory_girl'
require File.join(dir, '..', '..', 'spec', 'factories')
EOS

file "features/support/plain.rb", <<-EOS
Cucumber::Rails.use_transactional_fixtures
EOS

file "features/support/enhanced.rb", <<-EOS
require 'spec/expectations'
require 'selenium'
require 'webrat'

Webrat.configure do |config|
  config.mode = :selenium
  # Selenium defaults to using the selenium environment. Use the following to override this.
  config.application_environment = :test
end

require 'database_cleaner'
require 'database_cleaner/cucumber'
DatabaseCleaner.strategy = :truncation
EOS

file "features/step_definitions/setup_steps.rb", <<-EOS
Given /^there is a user called "([^\"]*)"$/ do |login|
  Factory(:user, :login => login) if User.find_by_login(login).nil?
end

Given /^I log in as "([^\"]*)"$/ do |login|
  @user = User.find_by_login(login)
  webrat.automate do
    visit login_path
    fill_in "user_session_login", :with => login
    fill_in "user_session_password", :with => 'secret'
    click_button 'Log in'
  end

  webrat.simulate do
    post "/user_session", :user_session => { :login => @user.login, :password => 'secret' }
  end
end

Given /^I am logged in as "([^\"]*)"$/ do |login|
  Given %(there is a user called "\#{login}")
  Given %(I log in as "\#{login}")
end
EOS

file "spec/factories.rb", <<-EOS
EOS

run "rm public/index.html"