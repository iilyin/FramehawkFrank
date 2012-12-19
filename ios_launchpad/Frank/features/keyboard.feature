Feature: Session Stability Test Suite

  Scenario: Launching the resetted app
    Given I reset the application and profiles
    Given I launch using username "iilyin@exadel.com", password "framehawk101", profile "Frank Automation"

  Scenario: Open the drawer
    Given I open the launchpad drawer

 Scenario: Start Google Drive session
    Given I check color of the cell
    Given I start a "Google Drive" session
    Given I log in to google drive
    Given I open template url
    Given I type abcde
    Given I check color of the cell