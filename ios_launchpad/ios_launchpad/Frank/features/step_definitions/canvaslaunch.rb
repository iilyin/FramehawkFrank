Given /^I check EULA$/ do
   step "I should see a \"I Accept\" button"
end

Given /^I accept EULA and see welcome$/ do
    step "I touch the button marked \"I Accept\""
    step "I wait to see \"Welcome to Framehawk\""
    step "I should see \"login_dialog_bg\""
end

Given /^I cancel login$/ do
    step "I touch the button marked \"Cancel\""
end

Given /^I launch using username "([^\"]*)", password "([^\"]*)"$/ do |username, password|
    step "I should see a \"I Accept\" button"
    step "I touch the button marked \"I Accept\""
    step "I should see \"Welcome to Framehawk\""
    step "I should see \"login_dialog_bg\""
    step "I wait to see \"Welcome to Framehawk\""
    step "I should see \"login_dialog_bg\""
    step "I type \"#{username}\" into the \"Enter user ID\" text field"
    step "I type \"#{password}\" into the \"Enter password\" text field"
    step "I touch the button marked \"OK\""
end

Given /^I check PIN visible$/ do
    step "I wait to see \"launchpad_splash\""
    step "I should see \"Setup PIN\""
end

Given /^I check login error visible$/ do
    step "I wait to see \"Incorrect User Id or Password\""
    step "I should see \"Incorrect User Id or Password\""
end

Given /^I enter PIN$/ do
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
    step "I wait for 2 second"
end

Given /^I check Profile selector$/ do
    step "I wait to see \"Choose a Profile\""
end

Given /^I relaunch the app$/ do
    steps "When I quit the simulator"
    steps "Given I launch the app"
end

Given /^I check PIN help visible$/ do
    step "I touch the button marked \"?\""
    step "I wait to see \"Framehawk Canvas PIN\""
    step "I should see \"Setup PIN\""
    step "I should see \"Set up or enter a PIN to access Framehawk Canvas\""
    step "I should see \"Close\""
end

Given /^I check PIN reset cancel$/ do
    step "I touch the button marked \"menu drawer tab\""
    step "I wait for the animation"
    step "I touch the button marked \"menu settings icon\""
    step "I wait for the animation"
    step "I should see \"Reset PIN\""
    step "I touch the button marked \"Reset PIN\""
    step "I wait to see \"Enter Old PIN\""
    step "I touch the button marked \"Cancel\""
    step "I wait to see \"menu drawer tab\""
    step "I should see \"menu drawer tab\""
end

Given /^I check PIN reset with wrong PIN$/ do
    step "I touch the button marked \"menu drawer tab\""
    step "I wait for the animation"
    step "I touch the button marked \"menu settings icon\""
    step "I wait for the animation"
    step "I should see \"Reset PIN\""
    step "I touch the button marked \"Reset PIN\""
    step "I wait to see \"Enter Old PIN\""
    step "I touch the button marked \"1\""
    step "I touch the button marked \"1\""
    step "I touch the button marked \"1\""
    step "I touch the button marked \"1\""
    step "I wait to see \"Wrong Pin! Try again.\""
    step "I should see \"Wrong Pin! Try again.\""
end

Given /^I check PIN reset with mismatch$/ do
    step "I touch the button marked \"menu drawer tab\""
    step "I wait for the animation"
    step "I touch the button marked \"menu settings icon\""
    step "I wait for the animation"
    step "I should see \"Reset PIN\""
    step "I touch the button marked \"Reset PIN\""
    step "I wait to see \"Enter Old PIN\""
    step "I touch the button marked \"1\""
    step "I touch the button marked \"2\""
    step "I touch the button marked \"3\""
    step "I touch the button marked \"4\""
    step "I wait to see \"Setup PIN\""
    step "I touch the button marked \"1\""
    step "I touch the button marked \"2\""
    step "I touch the button marked \"3\""
    step "I touch the button marked \"4\""
    step "I wait to see \"Re-enter PIN\""
    step "I touch the button marked \"1\""
    step "I touch the button marked \"1\""
    step "I touch the button marked \"1\""
    step "I touch the button marked \"1\""
    step "I wait to see \"PIN Mismatch. Try again!\""
    step "I should see \"PIN Mismatch. Try again!\""
end

Given /^I check PIN reset$/ do
    step "I touch the button marked \"menu drawer tab\""
    step "I wait for the animation"
    step "I touch the button marked \"menu settings icon\""
    step "I wait for the animation"
    step "I should see \"Reset PIN\""
    step "I touch the button marked \"Reset PIN\""
    step "I wait to see \"Enter Old PIN\""
    step "I touch the button marked \"1\""
    step "I touch the button marked \"2\""
    step "I touch the button marked \"3\""
    step "I touch the button marked \"4\""
    step "I wait to see \"Setup PIN\""
    step "I touch the button marked \"1\""
    step "I touch the button marked \"2\""
    step "I touch the button marked \"3\""
    step "I touch the button marked \"4\""
    step "I wait to see \"Re-enter PIN\""
    step "I touch the button marked \"1\""
    step "I touch the button marked \"2\""
    step "I touch the button marked \"3\""
    step "I touch the button marked \"4\""
    step "I wait to see \"menu drawer tab\""
    step "I should see \"menu drawer tab\""
end

