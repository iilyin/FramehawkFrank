Feature: Session Stability Test Suite

  Scenario: Launching the resetted app
    Given I reset the application and profiles
    Given I set studio url to http://studio-qa.framehawk.com
    Given I launch using username "sunil.joseph@framehawk.com", password "framehawk101", profile "Frank Automation"

  Scenario: Open the drawer
    Given I send swipes
