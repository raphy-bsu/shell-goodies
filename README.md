Shell Goodies
=============

Modify you bash environment the way you like.

## Features

* Some basic suit of bash functions
* Manager for bash files that contains useful functions
* Your personal scripts never will be lost. See plugins section

## How to install

Copy & paste in terminal:

```bash
sudo apt-get -y update && \
sudo apt-get -y install git-core ruby && \
git clone https://github.com/raphy-bsu/shell-goodies ~/.shell-goodies && \
cd ~/.shell-goodies && \
ruby goodies.rb install # Will require password for installation
```

## How to update

```bash
goodies update
```

## Plugins

We provide a number of useful functions. But, of course, we can not
give you all you need. So, we provide plugin manager to configure
your bash enviroment the way you like.

### What is plugin

Plugin is a git repository with your scripts.

### How it works

All `*.bash` scripts from your repository will be
defined in your `~/.bashrc` as `source <filename>`.

### Adding plugins

* Create file `~/.goodies-plugins`
* Write appropriate links (links for git clone) into file

### Apply changes

```bash
goodies update
```
