Feature: Setting up Dotify

  We need to be able to setup Dotify on our system.

  Scenario: Setting up dotify
    Given Dotify is not setup
    When I run `dotify setup --no-install --no-edit-config`
    Then a directory named ".dotify" should exist
    And a file named ".dotrc" should exist
