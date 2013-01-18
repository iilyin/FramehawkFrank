Feature: Profile Test Suite

  Scenario: Launching the resetted app
    Given I reset the simulator
    Given I launch the app
    Then I should see a "I Accept" button

  Scenario: Accepting the EULA and getting to the login page
    When I touch the button marked "I Accept"
    Then I should see "Welcome to Framehawk"
    Then I should see "login_dialog_bg"

  Scenario: Logging in with the incorrect credentials
    When I type "david.nguyen@framehawk.com" into the "Enter user ID" text field
    When I type "framehawk" into the "Enter password" text field
    When I touch the button marked "OK"
    Then I wait to see "Login Error!"
    Then I should see an alert view button marked "OK"
    When I wait for 5 seconds
    When I touch the alert view button marked "OK" at 20,20

  Scenario: Logging in with the correct credentials
    Then I wait to see "Welcome to Framehawk"
    Then I should see "login_dialog_bg"
    When I type "david.nguyen@framehawk.com" into the "Enter user ID" text field
    When I type "framehawk101" into the "Enter password" text field
    When I wait for 2 seconds
    When I touch the button marked "OK"
    Then I wait to see "launchpad_splash"
    Then I should see "Setup PIN"

  Scenario: The PIN should have 12 buttons
    Then I should see a "1" button
    Then I should see a "2" button
    Then I should see a "3" button
    Then I should see a "4" button
    Then I should see a "5" button
    Then I should see a "6" button
    Then I should see a "7" button
    Then I should see a "8" button
    Then I should see a "9" button
    Then I should see a "0" button
    Then I should see a "?" button
    Then I should see a "pin back button" button

  Scenario: Setting up the PIN incorrectly
    When I touch the button marked "1"
    When I touch the button marked "2"
    When I touch the button marked "3"
    When I touch the button marked "4"
    Then I wait to see "Re-enter PIN"
    When I touch the button marked "1"
    When I touch the button marked "1"
    When I touch the button marked "3"
    When I touch the button marked "4"
    Then I wait to see "PIN Mismatch. Try again!"
    Then I wait to see "Setup PIN"

  Scenario: Setting up the PIN correctly
    When I touch the button marked "1"
    When I touch the button marked "2"
    When I touch the button marked "3"
    When I touch the button marked "4"
    Then I wait to see "Re-enter PIN"
    When I touch the button marked "1"
    When I touch the button marked "2"
    When I touch the button marked "3"
    When I touch the button marked "4"
    Then I wait to see "Choose a Profile"

  Scenario: I should see an empty installed profile list upon startup
    When I touch the tab button marked "Installed"
    Then I should not see any profiles
    When I touch the tab button marked "Library"
    Then I should see profiles

  Scenario: I should see the uninstalled services in the Library tab
    When I touch the tab button marked "Library"
    Then I should see a nonhidden table view cell labeled "Framehawk Internal Services"

  Scenario: Selecting a Profile
    Then I wait for 30 seconds
    When I touch the table cell labeled "Framehawk Internal Services"
    Then I wait to see "menu drawer tab"
    Then I should see the following menu selection cells
      | GMail            |
      | HR Passport      |
      | Concur Solutions |
      | Yammer           |
      | Turbo Browser    |
      | Salesforce       |
      | HubSpot          |
      | Basecamp         |
      | Join.me          |
      | WorkSimple       |

  Scenario: Profile Dialog should appear
    When I wait for 5 seconds
    Given I open the profile selection menu

  Scenario: Installed Profile should not be in library
    When I touch the tab button marked "Installed"
    Then I should see a nonhidden table view cell labeled "Framehawk Internal Services"
    When I touch the tab button marked "Library"
    Then I should not see a hidden table view cell labeled "Framehawk Internal Services"

  Scenario: Install more Profile
    When I touch the tab button marked "Library"
    When I wait for 5 seconds
    Then I should see a nonhidden table view cell labeled "Framehawk Touch Services"
    When I touch the table cell labeled "Framehawk Touch Services"
    Then I wait to see "menu drawer tab"
	When I wait for 2 seconds
    Then I should see the following menu selection cells
      | GMail            |
      | HR Passport      |
      | Concur Solutions |
      | Yammer           |
      | Salesforce       |
      | Basecamp         |
      | WorkSimple       |

  Scenario: Verified that the new profile is installed
    When I wait for 5 seconds
    Given I open the profile selection menu
    When I touch the tab button marked "Installed"
    Then I should see a nonhidden table view cell labeled "Framehawk Touch Services"
    When I touch the tab button marked "Library"
    Then I should not see a hidden table view cell labeled "Framehawk Touch Services"

  Scenario: Switching to another installed profile
    When I touch the tab button marked "Installed"
	When I wait for 1 seconds
    Then I should see a nonhidden table view cell labeled "Framehawk Internal Services"
    When I touch the table cell labeled "Framehawk Internal Services"
    Then I wait to see "menu drawer tab"
	When I wait for 2 seconds
    Then I should see the following menu selection cells
      | GMail            |
      | HR Passport      |
      | Concur Solutions |
      | Yammer           |
      | Turbo Browser    |
      | Salesforce       |
      | HubSpot          |
      | Basecamp         |
      | Join.me          |
      | WorkSimple       |
    

