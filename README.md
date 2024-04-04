# rvm-windows

[![npm package](https://img.shields.io/npm/v/rvm-windows?color=default&style=plastic&logo=npm)](https://www.npmjs.com/package/rvm-windows)
![downloads](https://img.shields.io/npm/dt/rvm-windows?color=blue&style=plastic)
[![License: MIT](https://img.shields.io/badge/License-MIT-gold.svg?style=plastic&logo=mit)](LICENSE)

> Unofficial reimplementation of RVM.io (RVM) for MS Windows

As there is no RVM.io available for native windows, but only for POSIX by Cygwin, this is a reimplementation of basic [rvm.io](https://rvm.io/)
features for native MS Windows on the classic command line. It is based on the packages shipped by [rubyinstaller.org](https://rubyinstaller.org/).

Ruby environments are managed by RVM per user, but if you install your Rubies globally and just add their paths, you can manage them globally as well.

```diff
- Pre beta. Only for test purpose.

Missing basic features or known bugs:
- rvm uninstall 
- rvm upgrade
- automatically adding to PATH (init) breaks PATHs (of npm) sometimes
- define/set default version 
- rvm use system
```


> The goal of this project is not to 100% reimplement all features of 
> rvm.io, but the most important and common ones by preserving most of the
> same command line interface. And we may add some special Windows related stuff.

# Table of contents

* [Features](#features)
* [Usage](#usage)
* [Installation](#installation)
* [Troubleshooting](#troubleshooting)
* [Contributing](#contributing)

<a name="features"></a>

## Features
RVM 4 Windows allows you to comfortably install and manage several versions of Ruby on your Windows machine.

It automatically detects `.ruby-version` files or ruby version definitions in Gemfiles and runs your project on the classic windows command line on the specified ruby version automatically.

Beneath you can switch your ruby version instantly.

### Commands
The following commands are or will be available in rvm-windows:

```ruby
add <path>        # Add a installed ruby environment to the list
config            # Print current RVM config
current           # Print current ruby version
fix               # Automatically fix paths and versions in RVM configuration
help              # Print this usage guide
init              # Initialize RVM by adding to PATH environment variable
install           # Install a specific ruby version
kit               # Install x64 dependencies to build native gems like postgresql, mysql2, ...
list              # List all installed ruby versions managed by RVM
scan              # Scan for ruby installations and add them to the RVM configuration
update            # Check for RVM updates
use               # Switch to specified ruby version
version           # Display build version
```



<a name="usage"></a>

## Usage

### Usage example

```bash
rvm list
```



<a name="installation"></a>

## Installation

You can either use npm or yarn to install *rvm-windows*.

After install the command `rvm` is available on the command line.

On your command line execute the following command:

### yarn

```bash
yarn global add rvm-windows
```

### npm

```bash
npm install -g rvm-windows
```




<a name="troubleshooting"></a>

## Troubleshooting

### Does not run the selected ruby
Check if in your system wide PATH setting some ruby environment is listed and remove it from the system PATH variable.

Otherwise try
```
rvm init
```
or
```
rvm fix
```
again.


<a name="contributing"></a>

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/magynhard/rvm-windows. This project is
intended
to be a safe, welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

