Feature: Linking Files

  Sometimes we want to ignore certain dotfiles
  in our home directory (i.e. sensitive info,
  massive folders, etc...).

  @long_process
  Scenario: Linking files with ignored definitions
    Given a directory named ".dotify"
      And an empty file named ".dotrc"
      And an empty file named ".bash_profile"
      And an empty file named ".gemrc"
      And an empty file named ".vimrc"
      And an empty file named ".zshrc"
    And I write to ".dotrc" with:
      """
      ignore:
        dotfiles:
          - .gemrc
          - .zshrc
      """
    When I successfully run `dotify link --force`
    Then the following files should exist:
      | .dotify/.vimrc        |
      | .dotify/.bash_profile |
      And ".bash_profile" should be linked to Dotify
      And ".vimrc" should be linked to Dotify
      And the following files should not exist:
        | .dotify/.gemrc |
        | .dotify/.zshrc |
