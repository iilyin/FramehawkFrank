Feature: Session Stability Test Suite

  Scenario: Launching the resetted app
    Given I set studio url to http://studio-qa.framehawk.com
    Given I reset the application and profiles
    
  Scenario: Launch and cancel login
    Given I check EULA
    Given I accept EULA and see welcome
    Given I cancel login

  Scenario: I log in with valid credentials
    Given I set studio url to http://studio-qa.framehawk.com
    Given I reset the application and profiles
    Given I launch using username "iilyin@exadel.com", password "eklmn123"
    Given I check PIN visible

   Scenario: I log in with invalid credentials
    Given I set studio url to http://studio-qa.framehawk.com
    Given I reset the application and profiles
    Given I launch using username "a", password "b"
    Given I check login error visible

  Scenario: I check accound data saving
    Given I set studio url to http://studio-qa.framehawk.com
    Given I reset the application and profiles
    Given I launch using username "iilyin@exadel.com", password "eklmn123"
    Given I check PIN visible
    Given I enter PIN
    Given I relaunch the app
    Given I check PIN visible
    Given I enter PIN
    Given I check Profile selector

  Scenario: I check PIN help
    Given I set studio url to http://studio-qa.framehawk.com
    Given I reset the application and profiles
    Given I launch using username "iilyin@exadel.com", password "eklmn123"
    Given I check PIN visible
    Given I check PIN help visible

  Scenario: I check PIN help
    Given I set studio url to http://studio-qa.framehawk.com
    Given I reset the application and profiles
    Given I launch using username "iilyin@exadel.com", password "eklmn123"
    Given I check PIN visible
    Given I check PIN help visible       

  Scenario: I check PIN reset cancel
    Given I set studio url to http://studio-qa.framehawk.com
    Given I reset the application and profiles
    Given I launch using username "iilyin@exadel.com", password "eklmn123", profile "Frank Automation"
    Given I check PIN reset cancel

  Scenario: I check PIN incorect reset
    Given I set studio url to http://studio-qa.framehawk.com
    Given I reset the application and profiles
    Given I launch using username "iilyin@exadel.com", password "eklmn123", profile "Frank Automation"
    Given I check PIN reset with wrong PIN

  Scenario: I check PIN reset with mismatch
    Given I set studio url to http://studio-qa.framehawk.com
    Given I reset the application and profiles
    Given I launch using username "iilyin@exadel.com", password "eklmn123", profile "Frank Automation"
    Given I check PIN reset with mismatch

  Scenario: I check PIN reset
    Given I set studio url to http://studio-qa.framehawk.com
    Given I reset the application and profiles
    Given I launch using username "iilyin@exadel.com", password "eklmn123", profile "Frank Automation"
    Given I check PIN reset

