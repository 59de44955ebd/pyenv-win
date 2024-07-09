$pyenv_dir = $PSScriptRoot

function Get-Folder($initialDirectory="")
{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null
    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Select a folder"
    $foldername.rootfolder = "MyComputer"
    $foldername.SelectedPath = $initialDirectory
    if($foldername.ShowDialog() -eq "OK")
    {
        $folder += $foldername.SelectedPath
    }
    return $folder
}

function Setup-Version-Dir
{
	$pyenv_version_dir = "$pyenv_dir\versions"
	echo "By default pyenv installs Python versions into $pyenv_version_dir."
	$res = Read-Host "Do you want to select a different directory? [y/N]"
	if ($res -eq "y") {
		$pyenv_version_dir = Get-Folder
	} else {
		New-Item -ItemType "directory" -Path $pyenv_version_dir >nul
	}
	echo $pyenv_version_dir >"$pyenv_dir\versions_dir.txt"
}

if (!(Test-Path "$pyenv_dir\versions_dir.txt"))
{
	Setup-Version-Dir
}

$pyenv_version_dir = Get-Content -Path "$pyenv_dir\versions_dir.txt"

function Setup-Env
{
	echo "Prepending pyenv directory and %PYTHONHOME% to PATH variable ..."
	$oldpath = (get-item "HKCU:\Environment").GetValue("Path", $null, 'DoNotExpandEnvironmentNames')
	$newpath = "$pyenv_dir;%PYTHONHOME%;$oldpath"
	Set-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Environment' -Name Path -Value $newpath
	# Update for current Powershell
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Update-List
{
	$version_file = "$pyenv_dir\versions_list.txt"

	echo "Updating version list, please be patient ..."
	if (Test-Path "$version_file")
		{
		Remove-Item $version_file
	}
	$result = (Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/')
	foreach ($link in $result.Links)
	{
		if ($link.href.StartsWith('3') -or $link.href.StartsWith('4') -or $link.href.StartsWith('5'))
		{
			$pyversion = $link.href.substring(0, $link.href.length - 1)
			try
			{
				(Invoke-RestMethod -Uri "https://www.python.org/ftp/python/$pyversion/python-$pyversion-amd64.exe" -Method Head) | out-null
				echo $pyversion >> "$version_file"
			} catch {}
		}
	}
	echo "Done."
}

function Setup
{
	Setup-Env
	Update-List
}

function Install {
    param (
        $version
    )

	$installer_exe = "python-$version-amd64.exe"
	$target_dir = "$pyenv_version_dir\$version"

	if (Test-Path "$target_dir\") {
#		echo "[Error] Directory '$target_dir' already exists"
		$res = Read-Host "Remove existing directory ${TARGET_DIR}? [y/N]"
		if ($res -ne "y") {
			exit
		}
		echo "Removing $target_dir ..."
		Remove-Item "$target_dir" -Recurse
	}

	# download
	echo "Downloading $installer_exe from python.org ..."
	try {
		Invoke-WebRequest -Uri "https://www.python.org/ftp/python/$version/$installer_exe" -OutFile "$($env:TMP)\$installer_exe"
	}
	catch {
		Write-Error "[Error] Failed to download $installer_exe from python.org"
		exit 1
	}

	# unpack
	echo "Exctacting MSI files from $installer_exe ..."
	mkdir "$($env:TMP)\msi" | out-null
	$dark_exe = "$pyenv_dir\dark\dark.exe"
	Invoke-Expression "$dark_exe -nologo -x $($env:TMP)\msi $($env:TMP)\$installer_exe" | out-null

	# extracting
	echo "Extracting contents of MSI files to $target_dir ..."
	mkdir "$target_dir" | out-null

	Start-Process -wait "msiexec" "/quiet /a `"$($env:TMP)\msi\AttachedContainer\core.msi`" targetdir=`"$target_dir`""
	Start-Process -wait "msiexec" "/quiet /a `"$($env:TMP)\msi\AttachedContainer\dev.msi`" targetdir=`"$target_dir`""
	Start-Process -wait "msiexec" "/quiet /a `"$($env:TMP)\msi\AttachedContainer\doc.msi`" targetdir=`"$target_dir`""
	Start-Process -wait "msiexec" "/quiet /a `"$($env:TMP)\msi\AttachedContainer\exe.msi`" targetdir=`"$target_dir`""
	Start-Process -wait "msiexec" "/quiet /a `"$($env:TMP)\msi\AttachedContainer\lib.msi`" targetdir=`"$target_dir`""
	Start-Process -wait "msiexec" "/quiet /a `"$($env:TMP)\msi\AttachedContainer\tcltk.msi`" targetdir=`"$target_dir`""
	Start-Process -wait "msiexec" "/quiet /a `"$($env:TMP)\msi\AttachedContainer\test.msi`" targetdir=`"$target_dir`""

	# install pip
	echo "Installing pip ..."
	$pip_url = "https://bootstrap.pypa.io/get-pip.py" # for 3.7+
	if ($version.StartsWith('3.5')) {
		$pip_url = "https://bootstrap.pypa.io/pip/3.5/get-pip.py"
	}
	elseif ($version.StartsWith('3.6')) {
		$pip_url = "https://bootstrap.pypa.io/pip/3.6/get-pip.py"
	}
	try {
		Invoke-WebRequest -Uri "$pip_url" -OutFile "$target_dir\get-pip.py"
		$pythonhome_org = $env:PYTHONHOME
		$env:PYTHONHOME = $target_dir
		$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
		Invoke-Expression "& '$target_dir\python.exe' '$target_dir\get-pip.py'" >nul 2>nul
		$env:PYTHONHOME = $pythonhome_org
		$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
	}
	catch {
		Write-Error "[Error] Failed to download $PIP_URL"
	}

	# cleanup
	echo "Cleaning up ..."
	Remove-Item "$($env:TMP)\$installer_exe"
	Remove-Item "$($env:TMP)\msi" -Recurse
	Remove-Item "$target_dir\*.msi" -Recurse
	echo "Done."
}

function Uninstall {
    param (
        $version
    )

	$target_dir = "$pyenv_version_dir\$version"

	$res = Read-Host "Remove ${target_dir}? [y/N]"
	if ($res -ne "y") {
		exit
	}

	echo "Uninstalling Python $version ..."
	Remove-Item "$target_dir" -Recurse
	echo "Done."
}

function Local {
    param (
        $version
    )
	if (Test-Path "$pyenv_version_dir\$version\") {
		$env:PYTHONHOME = "$pyenv_version_dir\$version"
		$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
		Invoke-Expression "python -V"
	} else {
		echo "[Error] Version not available"
	}
}

function Global {
    param (
        $version
    )
	if (Test-Path "$pyenv_version_dir\$version\") {
		$env:PYTHONHOME = "$pyenv_version_dir\$version"
		setx PYTHONHOME "$env:PYTHONHOME" >nul
#		Set-ItemProperty -Path 'Registry::HKEY_CURRENT_USER\Environment' -Name PYTHONHOME -Value $env:PYTHONHOME
		$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
		Invoke-Expression "python -V"
	} else {
		echo "[Error] Version not available"
	}
}

function Versions {
	$sub_dirs = $(Get-ChildItem -Directory "$pyenv_version_dir");
	foreach($sub in $sub_dirs) {
		if ("$pyenv_version_dir\$($sub.Name)" -eq $env:PYTHONHOME) {
			echo "* $($sub.Name)"
		} else {
			echo "  $($sub.Name)"
		}
	}
}

function Pip-Transfer {
    param (
        $version_from,
        $version_to
    )

	$pythonhome_org = $env:PYTHONHOME

	if (!(Test-Path "$pyenv_version_dir\$version_from\")) {
		echo "[Error] Version $version_from is not installed."
		exit
	}

	if (!(Test-Path "$pyenv_version_dir\$version_to\")) {
		echo "Version $version_to is not installed."
		$res = Read-Host "Do you want to install it now? [y/N]"
		if ($res -ne "y") {
			exit
		}
		Install -version $version_to
		if (!(Test-Path "$pyenv_version_dir\$version_to\")) {
			echo "[Error] Version $version_to could not be installed."
			exit
		}
	}

	$env:PYTHONHOME = "$pyenv_version_dir\$version_from"
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
	Invoke-Expression "pip freeze >`"$($env:TMP)\~pip.txt`""

	$env:PYTHONHOME = "$pyenv_version_dir\$version_to"
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
	Invoke-Expression "pip install -U -r '$($env:TMP)\~pip.txt'"

	Remove-Item "$($env:TMP)\~pip.txt"
	$env:PYTHONHOME = $pythonhome_org
	$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
	echo "Done."
}

function Pip-Upgrade-All {
	Invoke-Expression "pip freeze >`"$($env:TMP)\~pip1.txt`""
	$data = (Import-Csv -Delimiter "=" -Path "$($env:TMP)\~pip1.txt" -Header 'name', 'version')
	Remove-Item "$($env:TMP)\~pip1.txt"
	foreach($row in $data){
		echo $row.name | Out-File -append "$($env:TMP)\~pip2.txt"
	}
	Invoke-Expression "pip install -U -r '$($env:TMP)\~pip2.txt'"
	Remove-Item "$($env:TMP)\~pip2.txt"
	echo "Done."
}

########################################
# START
########################################

if ($args.Count -gt 0 -and $args[0] -eq "setup") {
	Setup
	exit
}

if ($args.Count -gt 1 -and $args[0] -eq "local") {
	Local -version $args[1]
	exit
}

elseif ($args.Count -gt 1 -and $args[0] -eq "global") {
	Global -version $args[1]
	exit
}

elseif ($args.Count -gt 1 -and $args[0] -eq "install") {
	Install -version $args[1]
	exit
}

elseif ($args.Count -gt 1 -and $args[0] -eq "uninstall") {
	Uninstall -version $args[1]
	exit
}

elseif ($args.Count -gt 0 -and $args[0] -eq "list") {
	type "$pyenv_dir\versions_list.txt"
}

elseif ($args.Count -gt 0 -and $args[0] -eq "versions") {
	Versions
	exit
}

elseif ($args.Count -gt 0 -and $args[0] -eq "update-list") {
	Update-List
	exit
}

elseif ($args.Count -gt 2 -and $args[0] -eq "pip-transfer") {
	Pip-Transfer -version_from $args[1] -version_to $args[2]
	exit
}

elseif ($args.Count -gt 0 -and $args[0] -eq "pip-upgrade-all") {
	Pip-Upgrade-All
	exit
}

else {
echo @'

Usage: pyenv <command> [<version>]

Available commands:

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

'@
}
