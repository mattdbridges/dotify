Feature: Configuration Setup

  Configure Dotify to suit your needs.

  Scenario: Deafult setup when running `dotify setup`
    Given Dotify is not setup
    And I run `dotify setup`
    Then a file named ".dotrc" should exist
    And Dotify should have default configuration

  Scenario: Default setup with empty .dotrc file
    Given an empty file named ".dotrc"
    Then Dotify should have default configuration

  Scenario: Setup with non-empty .dotrc file
    Given Dotify is not setup
    And I run `dotify setup`
    And I write to ".dotrc" with:
    """
    editor: 'vi'
    """
    Then Dotify's editor should be "vi"
