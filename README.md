# pyenv-win - Poor man's pyenv for Windows
A simple script (both for PowerShell and CMD) that allows to install/uninstall/switch between/manage 64-bit Python 3 versions for Windows provided as binaries by [Python.org](https://www.python.org/downloads/windows/). 
The original installers (python-X.X.X-amd64.exe) are never executed, and therefor nothing is written to the Registry, other than updating the Path environment variable (in userspace) when (globally) switching between Python versions.

At the time of writing , 76 different Python versions can be installed, the earliest being 3.5.0 and the latest 3.12.4 (versions 3.4.x and earlier use different installers and are therefor not supported).

## Setup
Run this command in PowerShell:
```
iex (iwr "https://raw.githubusercontent.com/59de44955ebd/pyenv-win/main/install.txt").Content
```

## Usage
```
PS> pyenv

Usage: pyenv <command> [<arguments>]

Available commands:
===================

   install <version>         Install a Python version (download from python.org)

   uninstall <version>       Uninstall a Python version

   global <version>          Change the globally active Python version
                             (updates environment variables in userspace registry)

   local <version>           Change the local active Python version
                             (only for the current CMD or Powershell instance)

   versions                  List all Python versions currently installed via pyenv

   list                      List all Python versions that can be installed

   update-list               Update the list of installable Python versions available at python.org

   pip-transfer <from> <to>  Utility, tries to install all packages of version <from> in version <to>

   pip-upgrade-all           Utility, upgrades all outdated packages for the active Python version
```

## Example session (PowerShell)
```
PS> pyenv versions
* 3.12.4
PS> pyenv install 3.10.3
Downloading python-3.10.3-amd64.exe from python.org ...
Exctacting MSI files from python-3.10.3-amd64.exe ...
Extracting contents of MSI files to D:\dev\python\versions\3.10.3 ...
Installing pip ...
Cleaning up ...
Done.
PS> pyenv versions
  3.10.3
* 3.12.4
PS> pyenv global 3.10.3
Python 3.10.3
PS> pyenv versions
* 3.10.3
  3.12.4
PS>
```

## Example session (CMD)
```
C:\>pyenv versions
* 3.12.4

C:\>pyenv install 3.10.3
Downloading python-3.10.3-amd64.exe from python.org ...
Exctacting MSI files from python-3.10.3-amd64.exe ...
Extracting contents of MSI files to D:\dev\python\versions\3.10.3 ...
Installing pip ...
Cleaning up ...
Done.

C:\>pyenv versions
  3.10.3
* 3.12.4

C:\>pyenv global 3.10.3
Refreshing environment variables ...
Python 3.10.3

C:\>pyenv versions
* 3.10.3
  3.12.4

C:\>
```

## Notes
The tool dark.exe, which is used to extract .msi files from installers (python-X.X.X-amd64.exe) provided by [Python.org](https://www.python.org/downloads/windows/) without actually running the installer, is part of the [WiX Toolset ](https://github.com/wixtoolset/).
