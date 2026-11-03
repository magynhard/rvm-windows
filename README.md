<div align="center">
  <img src="src/assets/img/rvm-windows-icon.svg" alt="RVM — Ruby Version Manager 4 Windows" width="256"/>
</div>

# rvm-windows

[![GitHub release](https://img.shields.io/github/v/release/magynhard/rvm-windows.cr?color=default&style=plastic&logo=github)](https://github.com/magynhard/rvm-windows.cr/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/magynhard/rvm-windows.cr/total?color=blue&style=plastic)](https://github.com/magynhard/rvm-windows.cr/releases)
[![Windows build](https://img.shields.io/github/actions/workflow/status/magynhard/rvm-windows.cr/windows.yml?branch=master&style=plastic&label=Windows)](https://github.com/magynhard/rvm-windows.cr/actions/workflows/windows.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-gold.svg?style=plastic&logo=mit)](LICENSE)

> Reimplementation of the most important [rvm.io](https://www.rvm.io) features for native Windows, written in [Crystal](https://crystal-lang.org/).

As rvm.io is not available for native Windows, this is a reimplementation of its basic features for the Windows command line, based on the packages shipped by [rubyinstaller.org](https://rubyinstaller.org/).

RVM 4 Windows allows you to comfortably install and manage several versions of Ruby on your Windows machine.

It automatically detects `.ruby-version` files or Ruby version definitions in Gemfiles and runs your project with the specified Ruby version. You can also switch your Ruby version instantly.

This is the native Crystal port of [rvm-windows](https://github.com/magynhard/rvm-windows). **No Node.js or Crystal installation is required to use it.** Existing Ruby environments, configuration and sessions are retained.

Configuration is managed per user in `%USERPROFILE%\.rvm.json`, with terminal sessions in `%USERPROFILE%\.rvm\sessions`. Ruby environments are stored in `C:\ProgramData\rvm` by default.

> [!NOTE]
> The goal of this project is not to reimplement every feature of rvm.io, but the most important and common ones while preserving the familiar command-line interface. Some Windows-specific features are added as well.

## Table of contents

* [Features & Limitations](#features)
  * [MSYS2_PATH](#msys2_path)
* [Commands](#commands)
* [Usage](#usage)
* [Installation](#installation)
  * [Upgrading](#upgrading)
  * [Switching from the Node.js version](#switching-from-the-nodejs-version)
* [Troubleshooting](#troubleshooting)
  * [Does not run the selected Ruby](#trouble_selected_ruby)
  * [Using behind a proxy](#trouble_proxy)
* [Contributing](#contributing)

<a name="features"></a>
## Features & Limitations

* Automatic installation of RubyInstaller versions starting from 2.4.x, x64 only. Older installed Rubies can be added manually using `rvm add <path>`.
* Windows 10 or later, x64.
* Classic command line (CMD) and PowerShell.
* Automatic recognition of `.ruby-version` files and Ruby version definitions in Gemfiles, including parent directories.
* Only one environment per exact Ruby version: you can manage 3.3.0 and 3.3.1 separately, but not two installations of 3.3.1.
* Experimental `rvm kit` command with recipes for several Ruby versions to install common dependencies for native gems.
* Configurable proxy support; `HTTP_PROXY` and `HTTPS_PROXY` are temporarily set for wrapped Ruby commands.
* Native executable: no Node.js runtime or separate Crystal installation needed.

<a name="msys2_path"></a>
### MSYS2_PATH

When installing a new Ruby version, RVM by default installs a separate MSYS2 environment delivered by the devkit version of RubyInstaller.

If you want to use a central MSYS2 installation instead, set the `MSYS2_PATH` environment variable to its installation directory. RVM will download RubyInstaller without the devkit when that path contains a valid MSYS2 installation.

> [!WARNING]
> When using `MSYS2_PATH`, ensure that your central MSYS2 installation has all packages needed to build native gems for your Ruby versions. Older Ruby versions may not work with a newer MSYS2 installation.

<a name="commands"></a>
## Commands

The following commands are available:

```ruby
add <path>                 # Add an installed Ruby environment to the list (alias: mount)
automount                  # Scan for Ruby installations and add them to the configuration (alias: scan)
config                     # Print current RVM config
config data                # Print RVM data directory
config data <path>         # Set RVM data directory
config default             # Print default version
config default <version>   # Set default version
config proxy               # Get the configured proxy host
config proxy <host>        # Set the proxy host, e.g. http://proxy:12345
config proxy delete        # Remove the proxy host from the configuration
config proxy enable        # Enable the configured proxy
config proxy disable       # Disable the configured proxy
current                    # Print current Ruby environment version
default                    # Use default Ruby version (alias: rvm use default)
delete <version>           # Delete the given Ruby environment (alias: remove)
fix                        # Automatically fix paths, versions and wrappers
get                        # Upgrade RVM using the latest GitHub Release setup
help                       # Print this usage guide
info                       # Show environment information for current Ruby
init                       # Initialize RVM and its PATH configuration
install <version>          # Install a specific Ruby version
kick <version>             # Remove an environment from the list without deleting its files
kit                        # Experimental: install common x64 dependencies for native gems
list                       # List all installed Ruby versions managed by RVM
list verbose               # List installed versions with additional information
list known                 # List installable Ruby versions, latest patch per minor version
list all                   # List all installable Ruby versions
list upgrades              # List installed environments and available upgrades
mount <path>               # Add an installed Ruby environment (alias: add)
reinstall <version>        # Delete the given environment and install it again
remove <version>           # Delete the given Ruby environment (alias: uninstall)
scan                       # Scan for Ruby installations (alias: automount)
system                     # Use system Ruby (alias: rvm use system)
uninstall <version>        # Delete the given Ruby environment (alias: remove)
upgrade <version>          # Upgrade the given version to its latest patch version
upgrade <from> <to>        # Upgrade the given source version to the target version
use <version>              # Switch to the specified Ruby version
use --default <version>    # Switch to the specified version and set it as default
version                    # Display RVM build version
```

<a name="usage"></a>
## Usage

### List installed Rubies

```powershell
rvm list
```

<div style="background: black; color: white; border-radius: 16px;">
<pre>
 * <span style="color: #0088f8">ruby-3.2.2</span>
=> <span style="color: #0088f8">ruby-2.7.8</span>
   <span style="color: #0088f8">ruby-2.4.10</span>
<br/>
&#35; => - current
&#35; =* - current &amp;&amp; default
&#35;  * - default
</pre>
</div>

### List installable Rubies

```powershell
rvm list known
```

<div style="background: black; color: white; border-radius: 16px;">
<pre>
 - ruby-3.3.0
 - <span style="color: green">ruby-3.2.2</span>
 - ruby-3.1.4
 - ruby-3.0.6
 - <span style="color: green">ruby-2.7.8</span>
...
</pre>
</div>

Versions above are illustrative; the available releases are retrieved from RubyInstaller. Use `rvm list all` to include older patch versions.

### Switch version

You do not need to prefix the version with `ruby-`:

```powershell
rvm use 2.4.10
```

<div style="background: black; color: white; border-radius: 16px;">
<pre>
Using <span style="color: #0088f8">ruby-2.4.10</span> ...
</pre>
</div>

You do not need to specify the exact version either: RVM selects the highest matching **installed** version.

```powershell
rvm use 2
```

<div style="background: black; color: white; border-radius: 16px;">
<pre>
Using <span style="color: #0088f8">ruby-2.7.8</span> ...
</pre>
</div>

If the version is not installed yet, install it first using `rvm install <version>`.

### Additional shortcuts

There are shortcuts for common tasks, for example `rvm lv` instead of `rvm list verbose`:

```text
rvm list          -> rvm l
rvm list          -> rvm ls
rvm list verbose  -> rvm lv
rvm list known    -> rvm lk
rvm list all      -> rvm la
rvm list upgrades -> rvm lu
```

### Install a new version

You do not need to prefix `ruby-` or specify the exact version. RVM installs the highest matching version available:

```powershell
rvm install 3.2   # installs latest 3.2.x
rvm install 3     # installs latest 3.x.x
rvm install 2.7   # installs latest 2.7.x
rvm install 2     # installs latest 2.x.x
```

To make an installed version your default:

```powershell
rvm use --default 3.2
```

<a name="installation"></a>
## Installation

### Requirements

* Windows 10 or later, x64.
* No Node.js, npm, Crystal compiler or separate runtime installation required.

### Setup

1. Open the **[latest GitHub Release](https://github.com/magynhard/rvm-windows.cr/releases/latest)**.
2. Download `rvm-windows-<version>-windows-x64-setup.exe` from the release assets.
3. Run the setup wizard. It installs RVM for your Windows user and configures PATH.
4. Open a **new** CMD or PowerShell terminal and check the installation:

   ```powershell
   rvm version
   rvm help
   ```

All published versions are available on the [Releases page](https://github.com/magynhard/rvm-windows.cr/releases).

### Upgrading

Download the newer setup from [GitHub Releases](https://github.com/magynhard/rvm-windows.cr/releases/latest) and install it over the same application directory. Close running RVM commands first. Your configuration, installed Ruby environments and download cache are retained.

You can also use:

```powershell
rvm get
```

This downloads the latest published release setup and starts the update after the command exits. Restart your terminal after upgrading.

### Switching from the Node.js version

The Crystal version uses the same configuration, session files and Ruby environments as the original `rvm-windows`; you do not need to reinstall your Rubies.

> [!IMPORTANT]
> Setup regenerates the shared Ruby wrappers for the native executable. Do not use both implementations concurrently to change configuration or wrappers. To switch back to the Node.js version, restore its PATH priority and run its `rvm fix` command.

### ZIP alternative

If you prefer not to use setup, download the `rvm-windows-<version>-windows-x64.zip` asset, extract the **entire** package, and add its root directory to your user PATH. Open a new terminal and run `rvm init`.

Keep the supplied batch/PowerShell launchers and support files together. Use the `rvm` command through those launchers; do not add the private `bin` directory to PATH or call `bin/rvm.exe` directly for session-sensitive commands.

<a name="troubleshooting"></a>
## Troubleshooting

<a name="trouble_selected_ruby"></a>
### Does not run the selected Ruby

Check whether the system-wide PATH contains another Ruby environment before RVM's wrapper directory. Remove that Ruby entry from the system PATH if appropriate.

Otherwise try:

```powershell
rvm init
```

or:

```powershell
rvm fix
```

Then restart your terminal. If RVM reports that no session was found, ensure that you are using the supplied CMD/PowerShell launcher, not `bin/rvm.exe` directly.

<a name="trouble_proxy"></a>
### Using behind a proxy

RVM supports proxies with Basic Authentication. Configure your proxy using the following format:

```text
http://<username>:<password>@<proxy-hostname>:<proxy-port>
```

For example:

```powershell
rvm config proxy http://username:password@proxy.example:12345
```

#### NTLM & other authentication methods

For other authentication methods such as NTLM, use an intermediate proxy such as [px proxy](https://github.com/genotrance/px) or CNTLM.

To check that the intermediate proxy is running correctly:

```powershell
curl.exe -x http://127.0.0.1:3128 -X GET https://www.google.de
```

You should receive an HTML response. Then configure RVM to use the intermediate proxy:

```powershell
rvm config proxy http://127.0.0.1:3128
```

<a name="contributing"></a>
## Contributing

Bug reports and pull requests are welcome at [magynhard/rvm-windows.cr](https://github.com/magynhard/rvm-windows.cr).

For development setup, builds, tests, packaging and releases, see **[CONTRIBUTING.md](CONTRIBUTING.md)**.

This project is intended to be a safe, welcoming space for collaboration. Contributors are expected to adhere to the [Contributor Covenant](https://www.contributor-covenant.org/) code of conduct.

## License

[MIT](LICENSE), retaining the original project's author and license.
