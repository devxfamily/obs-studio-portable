# OBS Studio Portable

This project provides a convenient way to install OBS Studio in portable mode and use an enhanced version released by [DEV×FAMILY](https://github.com/devxfamily-fork/obs-studio/releases), which supports JsonPretty formatting and saves OBS Studio Source's file paths in relative form. These two features are required to make this fully portable possible. Currently, we only support Windows.

## Installation

### Automated Installation

1. Open PowerShell by pressing Win key + searching for `PowerShell` OR by pressing Win+R, then inputting `powershell`.

2. Copy and paste the following command into your PowerShell window:

- **Download and execute installation script silently:**
```pwsh
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Invoke-RestMethod -Uri "https://raw.githubusercontent.com/devxfamily/obs-studio-portable/main/install.ps1" | Invoke-Expression
```

- **Download and execute installation script with prompt:**
```pwsh
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
"function I{"+(Invoke-RestMethod -Uri "https://raw.githubusercontent.com/devxfamily/obs-studio-portable/main/install.ps1")+"} I -Prompt" | Invoke-Expression
```

### Manual Installation

1. Clone this repository:
   ```pwsh
   git clone https://github.com/devxfamily/obs-studio-portable.git
   ```

2. Navigate to the cloned directory:
   ```pwsh
   cd obs-studio-portable
   ```

3. Run the installation script in PowerShell:
     ```pwsh
     .\install.ps1 [-Prompt]
     ```
   If you want to be prompted during the installation process, include the -Prompt flag.

These commands will handle the setup process for you, including any necessary prompts if enabled. By default, the script installs OBS Studio Portable in the directory where you run it. If you run the script in your Home directory, it will create an obs-studio-portable folder there and install OBS Studio Portable inside it.

## Usage

### Open OBS Studio Portable directly by obs64.exe:

1. Navigate to the `bin\64bit` folder in the installation directory using File Explorer.

2. Run the `obs64.exe` executable located inside this folder.

### Open OBS Studio Portable by Shortcut:

After the installation on Windows, OBS Studio Portable automatically creates a shortcut in: `$env:APPDATA\Microsoft\Windows\Start Menu\Programs\OBS Studio Portable.lnk`.

1. Press the Win key and type "OBS Studio Portable" in the Start Menu search bar.

2. Select the shortcut from the search results.

Alternatively, locate the shortcut directly in: `$env:APPDATA\Microsoft\Windows\Start Menu\Programs\`, and double-click it to launch the application.

## Safety Disclaimer

Please ensure the safety and integrity of downloaded scripts before execution. Verify the source and authenticity of scripts, especially when using commands like Invoke-RestMethod.

## License

This project is licensed under the [MIT License](LICENSE).
