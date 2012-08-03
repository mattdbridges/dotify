Feature: Linking Files

  In order to manage dotfiles
  we need to be able to link files
  from the home directory -> ~/.dotify.

  Scenario: Linking files
    Given a directory named ".dotify"
      And an empty file named ".dotrc"
      And an empty file named ".bash_profile"
      And an empty file named ".gemrc"
      And an empty file named ".vimrc"
      And an empty file named ".zshrc"
      And I write to ".dotrc" with:
      """
      editor: 'vi'
      """
    When I successfully run `dotify link --force`
    Then ".bash_profile" should be linked to Dotify
      And ".gemrc" should be linked to Dotify
      And ".vimrc" should be linked to Dotify
      And ".zshrc" should be linked to Dotify
