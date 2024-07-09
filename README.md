# pyenv-win
Poor man's pyenv for Windows

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
Done.

C:\>pyenv versions
* 3.10.3
  3.12.4

C:\>
```
