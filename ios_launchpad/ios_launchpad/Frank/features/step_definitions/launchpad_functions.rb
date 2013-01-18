#######################
# Profile Functions
#######################

When /^I touch the tab button marked "(.*?)"$/ do |button_name|
  touch "view:'UITabBarButton' marked:'#{button_name}'"
end

Then /^I should not see a hidden table view cell labeled "([^\"]*)"$/ do |expected_mark|
  element_is_not_hidden("view:'UITableViewCell' marked:'#{expected_mark}'").should be_false
end

Then /^I should see a nonhidden table view cell labeled "([^\"]*)"$/ do |expected_mark|
  element_is_not_hidden("view:'UITableViewCell' marked:'#{expected_mark}'").should be_true
end
When /^I touch the table cell labeled "([^\"]*)"$/ do |label|
  touch "view:'UITableViewCell' view:'UILabel' marked:'#{label}'"
end

When /^I touch the table cell "([^\"]*)" info button$/ do |label|
  touch "view:'UITableViewCell' marked:'#{label}' button marked:'More info'"
end

Then /^I should not see any profiles$/ do
  profiles = frankly_map("view:'UITableView'", "visibleCells")
  (profiles[0].length == 0).should be_true
end

Then /^I should see profiles$/ do
  profiles = frankly_map("view:'UITableView'", "visibleCells")
  (profiles[0].length == 0).should be_false
end

Given /^I open the profile selection menu$/ do
  step "I touch the button marked \"menu profiles icon\""
  step "I wait to see \"profile_selection_bg\""
end

########################
# Alert Views Functions
########################

Then /^I should see an alert view button marked "([^\"]*)"$/ do |alert_label|
  check_element_exists("alertView button marked:'#{alert_label}'")
end

When /^I touch the alert view button marked "([^\"]*)" at ([\d\.]+),([\d\.]+)$/ do |mark,x,y|
  frankly_map("alertView button marked:'#{mark}'","touchx:y:",x,y)
end

########################
# Side Menu Functions
########################

When /^I touch the menu selection cell marked "([^\"]*)"$/ do |mark|
  touch "view:'MenuSelectionCell' marked:'#{mark}'"
end

Then /^I should see the menu selection cell "([^\"]*)" close button$/ do |mark|
  check_element_exists "view:'MenuSelectionCell' marked:'#{mark}' button marked:'menu close icon'"
end

Then /^I should not see the menu selection cell "([^\"]*)" close button$/ do |mark|
  !element_exists "view:'MenuSelectionCell' marked:'#{mark}' button marked:'menu close icon'"
end

When /^I touch the menu selection cell "([^\"]*)" close button$/ do |mark|
  touch "view:'MenuSelectionCell' marked:'#{mark}' button marked:'menu close icon'"
end

Then /^I should see the "([^\"]*)" menu selection cell unhighlighted$/ do |mark|
  check_element_exists "view:'MenuSelectionCell' marked:'#{mark}' view:'UIImageView' marked:'menu_item_unselected_bg.png'"
end

Then /^I should see the "([^\"]*)" menu selection cell highlighted$/ do |mark|
  check_element_exists "view:'MenuSelectionCell' marked:'#{mark}' view:'UIImageView' marked:'menu_item_selected_bg.png'"
end

When /^I should see the following menu selection cells$/ do |table|
  table.raw.each do |mark|
    check_element_exists "view:'MenuSelectionCell' marked:'#{mark}"
  end
end

Given /^I open the launchpad drawer$/ do
  step "I touch the button marked \"menu drawer tab\""
  step "I wait for the animation"
  step "I touch the button marked \"menu easy login icon\""
end

########################
# General Functions
########################

When /^I touch the navigation button marked "([^\"]*)"$/ do |mark|
  touch "view:'UINavigationButton' marked:'#{mark}'"
end

Then /^I wait for the animation$/ do
  wait_for_nothing_to_be_animating
end

########################
# Startup Functions
########################

Given /^I launch using username "([^\"]*)", password "([^\"]*)", profile "([^\"]*)"$/ do |username, password, profile|
  step "I should see a \"I Accept\" button"
  step "I touch the button marked \"I Accept\""
  step "I should see \"Welcome to Framehawk\""
  step "I should see \"login_dialog_bg\""
  step "I wait to see \"Welcome to Framehawk\""
  step "I should see \"login_dialog_bg\""
  step "I type \"#{username}\" into the \"Enter user ID\" text field"
  step "I type \"#{password}\" into the \"Enter password\" text field"
  step "I touch the button marked \"OK\""
  step "I wait to see \"launchpad_splash\""
  step "I should see \"Setup PIN\""
  step "I touch the button marked \"1\""
  step "I touch the button marked \"2\""
  step "I touch the button marked \"3\""
  step "I touch the button marked \"4\""
  step "I wait to see \"Re-enter PIN\""
  step "I touch the button marked \"1\""
  step "I touch the button marked \"2\""
  step "I touch the button marked \"3\""
  step "I touch the button marked \"4\""
  step "I wait to see \"Choose a Profile\""
  step "I touch the table cell labeled \"#{profile}\""
  step "I wait to see \"menu drawer tab\""
  step "I should see a \"menu easy login icon\" button"
end

