Feature: Session Stability Test Suite

  Scenario: Launching the resetted app
    Given I set studio url to http://studio-qa.framehawk.com
    Given I reset the application and profiles
    Given I launch using username "iilyin@exadel.com", password "eklmn123", profile "Frank Automation"

  Scenario: Open the drawer
    Given I open the launchpad drawer

 Scenario: Start Google Drive session
    Given I start a "Browser" session
    Given I log in to google drive
    Given I open template url
    Given I type abcde
    Given I check color of the cell
