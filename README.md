# rvm-windows

[![npm package](https://img.shields.io/npm/v/rvm-windows?color=default&style=plastic&logo=npm)](https://www.npmjs.com/package/rvm-windows)
![downloads](https://img.shields.io/npm/dt/rvm-windows?color=blue&style=plastic)
[![License: MIT](https://img.shields.io/badge/License-MIT-gold.svg?style=plastic&logo=mit)](LICENSE)

> Unofficial reimplementation of RVM.io (RVM) for MS Windows

As there is no RVM.io available for native windows, but only for POSIX by Cygwin, this is a reimplementation of rvm.io
features for native MS Windows.

```diff
- Pre alpha project template. Not ready for any use. ;-)
```


> The goal of this project is not to 100% reimplement all features of rvm.io, but the most important and common ones by preserving the
> same command line interface. And we may add some special Windows related stuff.

# Table of contents

* [Features](#features)
* [Usage](#usage)
* [Installation](#installation)
* [Contributing](#contributing)

<a name="features"></a>

## Features

The following commands are or will be available in rvm-windows:

```ruby
rvm add         # add a local installation to the rvm list
rvm current
rvm help
rvm install
rvm list
rvm use
rvm version
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

<a name="contributing"></a>

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/magynhard/rvm-windows. This project is
intended
to be a safe, welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

