# Dotify

[![Build Status](https://secure.travis-ci.org/mattdbridges/dotify.png)](http://travis-ci.org/mattdbridges/dotify) [![Dependency Status](https://gemnasium.com/mattdbridges/dotify.png)](https://gemnasium.com/mattdbridges/dotify)

Dotify is a simple CLI tool to make managing dotfiles on your system easy. When developing on a Linux/Unix basic system, keeping track of all of those dotfiles in the home directory can be pain. Some developers do not even bother managing them and many have come up with their own static or even dynamic way of managing them. This is a need in the community, and this tool makes managing these crazy files a breeze.

## Ruby Version Support

As this is a gem for use on your local system, I understand there are still many Ruby developers still stuck with using Ruby 1.8. As such, Dotify supports the following Ruby versions definitively:

* 1.8.7
* 1.9.2
* 1.9.3
* JRuby
* Rubinius

## Installation

It is highly recommended that you just install this gem manually since it is only managing files on your local system:Add this line to your application's Gemfile:

    $ gem install dotify

## Usage

As dotify is a CLI tool, everything is done in the command line. Here are the current available methods for managing dotfiles.

### Setting up and installing Dotify

To install Dotify, you must first run `dotify install` in your terminal.

    $ dotify install
        create /Users/computer-user/.dotify
        create /Users/computer-user/.dotrc
    Do you want to add .bash_history to Dotify? [Yn] n
    Do you want to add .bashrc to Dotify? [Yn] y
        create /Users/mattbridges/.dotify/.bashrc
    Do you want to add .railsrc to Dotify? [Yn] n
        create /Users/mattbridges/.dotify/.railsrc
    Do you want to add .zshrc to Dotify? [Yn] n
        create /Users/mattbridges/.dotify/.zshrc
    ...

This will first create a `.dotify` directory in your home directory as well as a `.dotrc` file for Dotify configuration (yes, it is more dotfiles, but this is a good thing!).

During the installation process, a Vim instance will open with a sample `.dotrc` file for you to edit and configure if you desire. This will allow your configuration to be used prior to Dotify's full installation. See more about the `.dotrc` file in the [Configuration](https://github.com/mattdbridges/dotify/tree/cli-rewrite#configuration) section.

Alternatively, you could run `dotify setup` to setup Dotify's configuration, followed by `dotify install` to add the initial files into Dotify.

### Add single files

After you have setup Dotify, you can add files one by one if you did not add them during setup

    $ dotify add .vimrc
          create  /Users/mattbridges/.vimrc

### Remove single files

If you don't want a particular dotfile anymore? You can just remove it.

***This actually removes the file from the home directory. Do this at your own risk***.

    $ dotify remove .vimrc
          remove  /Users/mattbridges/.vimrc

If you do this and decide to change your mind, the file is still located in the `~/.dotify` directory. You can re-link it by running `dotify link` again.

### Link up your files

This is the heart of the Dotify tool. This command will link the files within the `~/.dotify` directory into your home directory.

    $ dotify link
    Do you want to link .bash_profile to the home directory? [Yn] Y
          linked  /Users/mattbridges/.bash_profile
    Do you want to link .dotrc to the home directory? [Yn] n
    Do you want to link .gitconfig to the home directory? [Yn] Y
          linked  /Users/mattbridges/.gitconfig
    ...

You can also link files one-by-one by passing the filename to the `link` task.

    $ dotify link .bashrc
    Do you want to link ~/.bashrc? [Yn] Y
          linked  /Users/mattbridges/.bashrc

### Unlink everything

Don't want any of the dotfiles anymore? Well, I'm not one to question. Go ahead and wipe them out.

    $ dotify unlink
    Do you want to unlink .bashrc from the home directory? [Yn] y
          unlinked  /Users/computer-user/.bashrc
    Do you want to unlink .dotrc from the home directory? [Yn] n
    Do you want to unlink .gemrc from the home directory? [Yn] y
          unlinked  /Users/computer-user/.gemrc
    ...

Should you run this horrid task accidentally, you can simply run `dotify link` again if you want to restore your previous settings.

By default, `unlink` loops through all of the Dotify files. You can also pass a filename to `unlink` to unlink a single file.

    $ dotify unlink .bashrc
    Are you sure you want to remove ~/.bashrc? [Yn] Y
       remove /Users/mattbridges/.bashrc

## Versioning

The whole purpose of this gem was to manage the dotfiles on your system. What better way to do this than under version control using [Git](http://git-scm.com/) and [Github](https://github.com)?

* To version your Dotify installation, simple make `.dotify` a Git repository. If you don't know how to do that, I recommend you start reading [here](http://git-scm.com/book/en/Getting-Started).
* Add your remote repository via `git remote add [NAME] [REPO]`.

*From this point, you can manage your dotfiles entirely from Dotify.*

* To edit a dotfile managed by Dotify, simple run `dotify edit [DOTFILE]` and replace **[DOTFILE]** with the name of the file you want to edit. This will open a Vim instance containing that file for editing.
* Once you have saved your edits, simple run `dotify save` and Dotify will walk you through the steps of committing your changes and pushing them up to Github.

## Configuration

The `.dotrc` file in your home directory serves as the configuration file for Dotify. It is a [YAML](http://www.yaml.org/) formatted file.

#### Dotify Editor

When you run `dotify edit [DOTFILE]`, by default the file opens in Vim for editing. You can change this by adding this following to your `.dotrc` file.

    editor: 'vi'
    # or 'vim' or 'emacs' etc...

Vim and Emacs are the only two editors that have been successfully used with this configuration option, but if you find another, please [let me know](https://github.com/mattdbridges/dotify/issues/new) and I will update the documentation.

#### Ignoring files

When you are linking files in your Dotify directory, some files you do not want ever want to link (`.git`, `.gitmodules`, `.gitignore`, .etc) because they are used specifically for that directory (such as git versioning). You can configure Dotify to ignore these files when calling `dotify link` in the `.dotrc` in this way:

    $ cat ~/.dotrc
    ignore:
      dotify:
      - '.git'
      - '.gitmodules'
      - '.gitignore'

The same can be done for the home directory when running `dotify setup`. There are some directories that you should not move around (`.dropbox`, `.rbenv`, `.rvm`) and do not want to accidentally attempt to move. You can do that in your `.dotrc` file as well:

    $ cat ~/.dotrc
    ignore:
      dotfiles:
      - '.dropbox'
      - '.rbenv'
      - '.rvm'

More configuration options will likely be added in future versions, so be sure to check up here for your options.

## Clarifying the add/remove/link/unlink tasks

Here is a little clarification on the `add`/`remove`/`link`/`unlink` tasks.

* `dotify add` adds one or more dotfiles in the users' home directory into Dotify.
* `dotify remove` removes one or more linked dotfiles from Dotify and returns them to the home directory.
* `dotify link` links one or more files added to Dotify into the home directory.
* `dotify unlink` simply removes one or more home directory files that are linked into Dotify.

For instructions on how to use these methods, use `dotify help [TASK]` for further explanation.

## Not sure what to do?

This tool is powered by the amazing library, [Thor](http://whatisthor.com/). You can use the `help` task like so:

    $ dotify help
    Tasks:
      dotify add {{FILENAME}}     # Add a one or more dotfiles to Dotify. (FILENAME is optional)
      dotify edit [FILE]          # Edit a dotify file
      dotify help [TASK]          # Describe available tasks or one specific task
      dotify install              # Install files from your home directory into Dotify
      dotify link {{FILENAME}}    # Link up one or all of your dotfiles (FILENAME is optional)
      dotify remove {{FILENAME}}  # Remove a single dotfile from Dotify (FILENAME is optional)
      dotify save                 # Commit Dotify files and push to Github
      dotify setup                # Setup your system for Dotify to manage your dotfiles
      dotify unlink {{FILENAME}}  # Unlink one or all of your dotfiles (FILENAME is optional)
      dotify version              # Check your Dotify version

And if you want a little clarity on one of the command you can run `dotify help [TASK]` to find out what other options you have in the other tasks.

## Contributing

This tool is developed with much influence from *37singals*' fantastic idea of **Do Less**. This is meant to be a *simple* tool.

Contributions are welcome and encouraged. The contrubution process is the typical Github one.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new [Pull Request](https://github.com/mattdbridges/dotify/pull/new/master)
