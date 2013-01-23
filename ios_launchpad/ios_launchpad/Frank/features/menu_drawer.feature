Feature: Menu Drawer Test Suite

 Scenario: I log in with and touch Login Assistant button
  Given I set studio url to http://studio-qa.framehawk.com
  Given I reset the application and profiles
  Given I launch using username "iilyin@exadel.com", password "eklmn123", profile "Frank Automation"
  Given I click Login Assistant button in menu toolbar
  Then I wait for the animation
  Given I start a "Browser" session
  Given I click Login Assistant button in menu toolbar
  Given I touch the button marked "No Thanks" 
  
 
 

  