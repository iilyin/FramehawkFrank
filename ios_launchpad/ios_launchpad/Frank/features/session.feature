Feature: Session Stability Test Suite

  Scenario: Launching the resetted app
    Given I reset the application
    Given I launch using username "david.nguyen@framehawk.com", password "framehawk101", profile "Framehawk Internal Services"

  Scenario: Open the drawer
    Given I open the launchpad drawer

  Scenario: 4 Session stress test
    Then I test the four session limits 100 times on three of the following sessions
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

  Scenario: Open Session stress test
    Then I open and close 100 iterations of three of the following sessions
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

