param (
    [switch]$Prompt
)

function Get-BashPath {
    $bashCommand = "bash"
    $bashPath = Get-Command $bashCommand -ErrorAction SilentlyContinue

    if ($null -ne $bashPath) {
        return $bashPath.Source
    }

    $programFilesPath = [Environment]::GetFolderPath("ProgramFiles")
    $gitBashPath = Join-Path $programFilesPath "Git\bin\bash.exe"

    if (Test-Path $gitBashPath) {
        return $gitBashPath
    }

    return $null
}

function Test-ScoopInstalled {
    $scoopPath = Get-Command scoop -ErrorAction SilentlyContinue
    return $null -ne $scoopPath
}

function Install-Scoop {
    Write-Host "Installing Scoop..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri "https://get.scoop.sh" | Invoke-Expression
}

function Test-GitInstalled {
    $gitPath = Get-Command git -ErrorAction SilentlyContinue
    return $null -ne $gitPath
}

function Install-GitViaScoop {
    Write-Host "Installing Git via Scoop..."
    scoop install git
    Write-Host "Git with Bash should now be installed."
}

function InstallScoopAndGitIfNeeded {
    if (-not (Test-ScoopInstalled)) {
        if ($Prompt) {
            $installScoop = Read-Host "Scoop is a package manager for Windows, and it's required to install the necessary dependencies for OBS Studio. Do you want to install Scoop? (Y/n)"
            if ($installScoop -eq "N" -or $installScoop -eq "n") {
                Write-Output "Installation cancelled."
                exit 1
            }
        }
        Install-Scoop
    }
    if ((Test-ScoopInstalled) -and -not (Test-GitInstalled)) {
        if ($Prompt) {
            $installGit = Read-Host "Git is a version control system required by this installation script to continue the process. Do you want to install Git via Scoop? (Y/n)"
            if ($installGit -eq "N" -or $installGit -eq "n") {
                Write-Output "Installation cancelled."
                exit 1
            }
        }
        Install-GitViaScoop
    }
}

function Test-BashCommand {
    $bashPath = Get-BashPath

    if ($null -ne $bashPath) {
        Write-Host "Bash command found at $bashPath"
        return $true
    }

    Write-Host "Bash command not found."

    InstallScoopAndGitIfNeeded

    return (Test-ScoopInstalled -and Test-GitInstalled)
}

function RunBashScript {
    # Check if bash command exists
    $bashExists = Test-BashCommand

    if (!$bashExists) {
        Write-Host "Cannot find bash.exe execution stopped!"
        return
    }

    $bashPath = Get-BashPath
    if ($Prompt) { $arguments = '--prompt' }

    if (Test-Path -Path ".\install.sh") {
        # If local install.sh exists, execute it directly using bash
        & $bashPath .\install.sh $arguments
        return
    }

    # Define the URL of the script to download
    $installScriptUrl = "https://raw.githubusercontent.com/devxfamily/obs-studio-portable/main/install.sh"

    # Create a temporary file path
    $tempFile = [System.IO.Path]::GetTempFileName()

    # Download the script directly to the temporary file
    Invoke-WebRequest -Uri $installScriptUrl -OutFile $tempFile

    # Execute the downloaded script using bash
    & $bashPath $tempFile $arguments

    # Remove the temporary file
    Remove-Item -Path $tempFile
}

function CheckAndInstallVCRedist2022 {
    $redistInstalled = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" `
                      | Where-Object { $_.DisplayName -like "Microsoft Visual C++ 2022*" }

    if (-not $redistInstalled) {
        if ($Prompt) {
            $installPermission = Read-Host "OBS Studio requires the Microsoft Visual C++ 2022 Redistributable to run properly. Do you want to install it? (Y/n)"
            if ($installPermission -eq "N" -or $installPermission -eq "n") {
                Write-Output "Installation cancelled."
                exit 1
            }
        }

        InstallScoopAndGitIfNeeded

        # Check if the extras bucket is installed and add it if not
        $extrasBucket = scoop bucket list | Select-String -Pattern "extras"
        if (-not $extrasBucket) {
            Write-Output "Adding extras bucket to Scoop."
            scoop bucket add extras
        }
        
        Write-Output "Installing Visual C++ Redistributable 2022."
        scoop install vcredist2022
    }
}

function New-OBS-Studio-Shortcut {
    # Define paths
    $obsExecutablePath = (Resolve-Path -Path ".\bin\64bit\obs64.exe").Path
    $shortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\OBS Studio Portable.lnk"
    $startInDirectory = (Resolve-Path -Path ".\bin\64bit\").Path

    # Check if the shortcut already exists
    if (Test-Path $shortcutPath) {
        if ($Prompt) {
            $replaceShortcut = Read-Host "OBS Studio Portable shortcut found. Do you want to replace it? [Y/n]"
            if ($replaceShortcut -eq "N" -or $replaceShortcut -eq "n") {
                return
            }
        }
    }

    # Create shortcut
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $obsExecutablePath
    $shortcut.WorkingDirectory = $startInDirectory  # Set the "Start in" property
    $shortcut.Save()

    Write-Host "Created shortcut $shortcutPath -> $obsExecutablePath"
}

if ($PWD.Path -eq $HOME) {
    Write-Host "Current directory is your home directory."
    $portableDir = Join-Path -Path $HOME -ChildPath "obs-studio-portable"
    if (-not (Test-Path -Path $portableDir -PathType Container)) {
        New-Item -ItemType Directory -Path $portableDir | Out-Null
    }
    Set-Location -Path $portableDir
    Write-Host "Changed to 'obs-studio-portable' directory."
}

RunBashScript
CheckAndInstallVCRedist2022
New-OBS-Studio-Shortcut