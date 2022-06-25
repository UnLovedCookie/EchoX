set Version=7.1
set DevBuild=No
::https://tinyurl.com/echolicence
@echo off
Mode 52,16
title EchoX
color fc
cd %temp%

::Enable Delayed Expansion
setlocal EnableDelayedExpansion

::Begin Log
echo Begin Log >%temp%\EchoLog.txt
echo Begin Error Log >%temp%\EchoError.txt

::Choice Prompt Setup
for /f %%A in ('"prompt $H &echo on &for %%B in (1) do rem"') do set BS=%%A

::Check For PowerShell
if not exist "%windir%\system32\WindowsPowerShell\v1.0\powershell.exe" (
call:EchoXLogo
echo.
echo %BS%               Missing PowerShell 1.0
echo %BS%          press any key to continue anyway
choice /c:"CQ" /n /m "%BS%               [C] Continue  [Q] Quit" & if !errorlevel! equ 2 exit /b
)

::Get Admin Rights
if exist "%SystemDrive%\Windows\system32\adminrightstest" (rmdir %SystemDrive%\Windows\system32\adminrightstest >nul 2>&1)
mkdir %SystemDrive%\Windows\system32\adminrightstest >nul 2>&1
if %errorlevel% neq 0 (
call:EchoXLogo
echo.
echo                  Run EchoX as Admin
start "" /wait /I /min powershell -NoProfile -Command start -verb runas "'%~s0'"
exit /b
)

::Check For Internet
Ping www.google.nl -n 1 -w 1000 >nul
if %errorlevel% neq 0 (
call:EchoXLogo
echo.
echo %BS%               No Internet Connection
echo %BS%          connect or press any key to skip
choice /c:"CQ" /n /m "%BS%               [C] Continue  [Q] Quit" & if !errorlevel! equ 2 exit /b
)

::Run CMD in 32-Bit
set SystemPath=%SystemRoot%\System32
if not "%ProgramFiles(x86)%"=="" (if exist %SystemRoot%\Sysnative\* set SystemPath=%SystemRoot%\Sysnative)
if "%processor_architecture%" neq "AMD64" (start "" /I "%SystemPath%\cmd.exe" /c "%~s0" & exit /b)

::Check For Updates
if "%DevBuild%" neq "Yes" (
set DL=https://pastebin.com/raw/SLQzhFZY
if exist "%windir%\system32\windowspowershell\v1.0\powershell.exe" (powershell wget !DL! -OutFile "%temp%\latestVersion.bat") else (bitsadmin /transfer "" !DL! "%temp%\latestVersion.bat") >nul 2>&1
call "%temp%\latestVersion.bat"
if "%Version%" neq "!latestVersion!" (cls
call:EchoXLogo
echo       Warning, EchoX isn't updated.
echo  Download version !latestVersion! on the Discord, dsc.gg/echox
echo                    ^(Put the URL in your browser^)
echo.
choice /c:"CQ" /n /m "%BS%               [C] Continue  [Q] Quit" & if !errorlevel! equ 2 exit /b
)
)

::Settings
call:EchoXLogo
echo            Loading Settings [...]

::Nvidia Driver
set cdCache=%cd%
cd "%SystemDrive%\Program Files\NVIDIA Corporation\NVSMI\" >nul 2>&1
(for /f "tokens=1" %%a in ('nvidia-smi --query-gpu^=driver_version --format^=csv') do set NvidiaDriverVersion=%%a) >nul 2>&1
cd %cdCache%

if not exist "%SystemRoot%\System32\wbem\WMIC.exe" (
::WMI Settings
Reg add "HKCU\Software\Echo" /f >nul 2>&1
powershell -ExecutionPolicy Unrestricted -NoProfile import-module Microsoft.PowerShell.Management;import-module Microsoft.PowerShell.Utility;^
$GPU = Get-WmiObject win32_VideoController ^| Select-Object -ExpandProperty Name;Set-ItemProperty -Path "HKCU:\Software\Echo" -Name "GPU_NAME" -Type String -Value "$GPU";^
$mem = Get-WmiObject win32_operatingsystem ^| Select-Object -ExpandProperty TotalVisibleMemorySize;Set-ItemProperty -Path "HKCU:\Software\Echo" -Name "mem" -Type String -Value "$mem";^
$ChassisTypes = Get-WmiObject win32_SystemEnclosure ^| Select-Object -ExpandProperty ChassisTypes;Set-ItemProperty -Path "HKCU:\Software\Echo" -Name "ChassisTypes" -Type String -Value "$ChassisTypes";^
$Degrees = Get-WmiObject -Namespace "root/wmi" MSAcpi_ThermalZoneTemperature ^| Select-Object -ExpandProperty CurrentTemperature;Set-ItemProperty -Path "HKCU:\Software\Echo" -Name "Degrees" -Type String -Value "$Degrees";^
$CORES = Get-WmiObject win32_processor ^| Select-Object -ExpandProperty NumberOfCores;Set-ItemProperty -Path "HKCU:\Software\Echo" -Name "CORES" -Type String -Value "$CORES";^
$osarchitecture = Get-WmiObject win32_operatingsystem ^| Select-Object -ExpandProperty osarchitecture;Set-ItemProperty -Path "HKCU:\Software\Echo" -Name "osarchitecture" -Type String -Value "$osarchitecture"
for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v CORES') do set CORES=%%a
for /f "tokens=*" %%a in ('Reg query "HKCU\Software\Echo" /v GPU_NAME') do set GPU_NAME=%%a
for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v mem') do set mem=%%a
for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v ChassisTypes') do set ChassisTypes=%%a
for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v Degrees') do set Degrees=%%a
for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v osarchitecture') do set osarchitecture=%%a
) >nul 2>&1 else (
::Faster WMIC Settings
rem for /f "tokens=2 delims==" %%n in ('wmic /namespace:\\root\wmi path MSAcpi_ThermalZoneTemperature get CurrentTemperature /value') do set Degrees=%%n
rem for /f "delims=" %%n in ('"wmic path Win32_VideoController get CurrentHorizontalResolution,CurrentVerticalResolution /format:value"') do set "%%n" >nul 2>&1
for /f "tokens=2 delims==" %%n in ('wmic os get TotalVisibleMemorySize /format:value') do set ram=%%n
for /f "tokens=2 delims==" %%n in ('wmic path Win32_VideoController get Name /format:value') do set GPU_NAME=%%n
for /f "tokens=2 delims==" %%n in ('wmic cpu get numberOfCores /format:value') do set CORES=%%n
for /f "tokens=2 delims={}" %%n in ('wmic path Win32_SystemEnclosure get ChassisTypes /format:value') do set /a ChassisTypes=%%n
) >nul 2>&1

::MS Account
for /f %%i in ('powershell -NoProfile -Command "Get-LocalUser | Select-Object Name,PrincipalSource"') do set "str=%%i" & if "!str!" neq "!str:MicrosoftAccount=!" set Account=MS

::NSudo
if not exist "%temp%\NSudo.exe" (
echo            Downloading NSudo [...]
set DL=https://github.com/Xt5gamerxX/Echo/raw/main/Files/NSudo.exe
if exist "%windir%\system32\windowspowershell\v1.0\powershell.exe" (powershell wget !DL! -OutFile "%temp%\NSudo.exe") else (bitsadmin /transfer "" !DL! "%temp%\NSudo.exe") >nul 2>&1
)

::restart64
if not exist "%temp%\restart64.exe" (
echo            Downloading Files [...]
set DL=https://github.com/Xt5gamerxX/Echo/raw/main/Files/restart64.exe
if exist "%windir%\system32\windowspowershell\v1.0\powershell.exe" (powershell wget !DL! -OutFile "%temp%\Restart64.exe") else (bitsadmin /transfer "" !DL! "%temp%\Restart64.exe") >nul 2>&1
)

::Setup Nsudo
Start "" /wait "%temp%\NSudo.exe" -U:S -ShowWindowMode:Hide cmd /c "Reg add "HKLM\SYSTEM\CurrentControlSet\Services\TrustedInstaller" /v "Start" /t Reg_DWORD /d "3" /f"
Start "" /wait "%temp%\NSudo.exe" -U:S -ShowWindowMode:Hide cmd /c "sc start "TrustedInstaller"

::Extra Settings
set DualBoot=Unknown
set storageType=Unknown
set CPU_NAME=%PROCESSOR_IDENTIFIER%
set THREADS=%NUMBER_OF_PROCESSORS%

::Nvidia Drivers
if 1 neq 1 if "%NvidiaDriverVersion%" neq "457.30" (
call:EchoXLogo
echo.
echo        Recommended graphics driver not found:
choice /c:12 /n /m "%BS%               [1] Install  [2] Skip"
if !errorlevel!==1 (cls
echo Downloading Nvidia Driver [...]
if exist "%temp%\457.30x64Desktop.exe" del "%temp%\457.30x64Desktop.exe"
Reg query "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "DCHUVen" >nul 2>&1
if !errorlevel! equ 0 (set "DL=https://onedrive.live.com/download?cid=91FD8D99AB112B7E&resid=91FD8D99AB112B7E%%21108&authkey=AHcg0GQ-iB6_-AM") else (set "DL=https://onedrive.live.com/download?cid=91FD8D99AB112B7E&resid=91FD8D99AB112B7E%%21106&authkey=AOw9OffeXfkCw8w")
powershell "wget '!DL!' -OutFile '%temp%\457.30x64Desktop.exe'" >nul 2>&1
echo Installing Nvidia Driver [...]
"%temp%\457.30x64Desktop.exe"
if !errorlevel! neq 0 (cls & echo Failed to install Nvidia Drivers [...] & echo You'll have to manually install Nvidia Driver 457.30) else (cls & echo Installed Nvidia Drivers [...])
choice /c:"CQ" /n /m "%BS%               [C] Continue  [Q] Quit" & if !errorlevel! equ 2 exit /b
)
)

::Ask about Restore Points
(for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v Restore') do set Restore=%%a) >nul 2>&1
if "%Restore%" equ "" (cls
call:EchoXLogo
echo.
echo           Let EchoX create a Restore Point
echo              (Used to undo all changes^)
choice /c:NY /n /m "%BS%                  [Y] Yes  [N] No"
Reg add "HKCU\Software\Echo" /v Restore /t Reg_DWORD /d "!errorlevel!" /f >nul
)

::Check For 64-Bit
if "%PROCESSOR_ARCHITECTURE%" equ "x86" (cls
call:EchoXLogo
echo.
echo %BS%                64-bit Not Detected
echo %BS%          press any key to continue anyway
choice /c:"CQ" /n /m "%BS%               [C] Continue  [Q] Quit" & if !errorlevel! equ 2 exit /b
)

if "%Account%" equ "MS" (cls
call:EchoXLogo
echo.
echo %BS%             Microsoft Account Detected
echo %BS%          presasdasdasds any key to continue anyway
choice /c:"CQ" /n /m "%BS%               [C] Continue  [Q] Quit" & if !errorlevel! equ 2 exit /b
)

::Auto Detect Settings	
(for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v Throttling') do set Throttling=%%a) >nul 2>&1
if defined ChassisTypes if %ChassisTypes% GEQ 8 if %ChassisTypes% LSS 12 (
if "%Throttling%" equ "" Reg add "HKEY_CURRENT_USER\SOFTWARE\Echo" /v Throttling /t Reg_DWORD /d "1" /f >nul
)

rem start "EchoX" /I cmd /c "@echo off & Mode 52,16 & color fc & powershell wget http://optimize.mygamesonline.org/database -OutFile C:\windows\system32\database && call ^"%~s0^" && exit /b 0"
:Home
cls
call:EchoXLogo
echo           [91m[[94m1[91m] Optimize  [[94m2[91m] More
echo                 [[94m3[91m] Undo  [[94m4[91m] Credits
echo.
choice /c:1234 /n /m "%BS%                                   >:"
set MenuItem=%errorlevel%

if "%MenuItem%"=="1" goto Optimize
if "%MenuItem%"=="2" set "SettingsPage=1" & goto Settings
if "%MenuItem%"=="3" goto Undo
if "%MenuItem%"=="4" goto Credits

:Settings
set SettingsItem=Undefined

cls
if "%SettingsPage%"=="1" (
echo                        EXTRA
echo.
echo.
echo.
echo [[94m1[91m] Game Booster
echo Select games to specificaly boost
echo.
echo.
echo.
echo [[94m2[91m] Soft-Restart
echo Speeds up PC by restarting internet and graphics
echo.
echo.
echo.
choice /c:1234NB /n /m "%BS%                [N] Next   [B] Back"
set /a SettingsItem=!errorlevel!
if "!SettingsItem!"=="5" (set SettingsPage=2)
cls
)

if "%SettingsItem%"=="1" call:gameBooster & goto Home
if "%SettingsItem%"=="2" call:softRestart & goto Home
if %SettingsItem% lss 5 goto Settings

if "%SettingsPage%"=="2" (
for %%i in (MaxPow Idle Throttling pstates) do (set %%i=off & for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v %%i') do if "%%a"=="0x1" set %%i=on) >nul 2>&1
echo                        POWER
echo.
echo [[94m1[91m] Maximum Power Plan [32m!MaxPow![91m
echo Enable for more performance and heat
echo.
echo [[94m2[91m] Power-Throttling [32m!Throttling![91m
echo Turn this on if you're on a laptop
echo.
echo [[94m3[91m] Disable Idle [32m!Idle![91m
echo Can generate more heat but has more stable FPS
echo.
echo [[94m4[91m] PStates 0 [32m!pstates![91m
echo Enable for more performance and heat
echo.
choice /c:1234NB /n /m "%BS%                [N] Next   [B] Back"
set /a SettingsItem=!errorlevel!
if "!SettingsItem!"=="5" (set SettingsPage=3)
cls
)

if "%SettingsItem%"=="1" if "%MaxPow%"=="on" (Reg add "HKEY_CURRENT_USER\SOFTWARE\Echo" /v MaxPow /t Reg_DWORD /d "0" /f >nul) else (Reg add "HKEY_CURRENT_USER\SOFTWARE\Echo" /v MaxPow /t Reg_DWORD /d "1" /f >nul)
if "%SettingsItem%"=="2" if "%Throttling%"=="on" (Reg add "HKEY_CURRENT_USER\SOFTWARE\Echo" /v Throttling /t Reg_DWORD /d "0" /f >nul) else (Reg add "HKEY_CURRENT_USER\SOFTWARE\Echo" /v Throttling /t Reg_DWORD /d "1" /f >nul)
if "%SettingsItem%"=="3" if "%Idle%"=="on" (Reg add "HKEY_CURRENT_USER\SOFTWARE\Echo" /v Idle /t Reg_DWORD /d "0" /f >nul) else (Reg add "HKEY_CURRENT_USER\SOFTWARE\Echo" /v Idle /t Reg_DWORD /d "1" /f >nul)
if "%SettingsItem%"=="4" if "%pstates%"=="on" (Reg add "HKEY_CURRENT_USER\SOFTWARE\Echo" /v pstates /t Reg_DWORD /d "0" /f >nul) else (Reg add "HKEY_CURRENT_USER\SOFTWARE\Echo" /v pstates /t Reg_DWORD /d "1" /f >nul)
if %SettingsItem% lss 5 goto Settings

if "%SettingsPage%"=="3" (
for %%i in (Debloat DisplayScaling Restore KBoost) do (set %%i=off & for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v %%i') do if "%%a"=="0x1" set %%i=on) >nul 2>&1
echo                       ADVANCED
echo.
echo [[94m1[91m] ADVANCED Debloat [32m!Debloat![91m
echo Removes Windows features and can cause BSOD
echo.
echo [[94m2[91m] Disable Display Scaling [32m!DisplayScaling![91m
echo Turn this on to disable display scaling
echo.
echo [[94m3[91m] KBoost [32m!KBoost![91m
echo Turn this off if your computer gets hot
echo.
echo [[94m4[91m] Don't Create A Restore Point [32m!Restore![91m
echo Not recommended to turn this off
echo.
choice /c:1234NB /n /m "%BS%                [N] Next   [B] Back"
set SettingsItem=!errorlevel!
if "!SettingsItem!"=="5" (set SettingsPage=4)
cls
)

if "%SettingsItem%"=="1" if "%Debloat%"=="on" (Reg add "HKEY_CURRENT_USER\SOFTWARE\Echo" /v Debloat /t Reg_DWORD /d "0" /f >nul) else (Reg add "HKEY_CURRENT_USER\SOFTWARE\Echo" /v Debloat /t Reg_DWORD /d "1" /f >nul)
if "%SettingsItem%"=="2" if "%DisplayScaling%"=="on" (Reg add "HKCU\Software\Echo" /v DisplayScaling /t Reg_DWORD /d "0" /f >nul) else (Reg add "HKCU\Software\Echo" /v DisplayScaling /t Reg_DWORD /d "1" /f >nul)
if "%SettingsItem%"=="3" if "%KBoost%"=="on" (Reg add "HKEY_CURRENT_USER\SOFTWARE\Echo" /v KBoost /t Reg_DWORD /d "0" /f >nul) else (Reg add "HKEY_CURRENT_USER\SOFTWARE\Echo" /v KBoost /t Reg_DWORD /d "1" /f >nul)
if "%SettingsItem%"=="4" if "%Restore%"=="on" (Reg add "HKEY_CURRENT_USER\SOFTWARE\Echo" /v Restore /t Reg_DWORD /d "0" /f >nul) else (Reg add "HKEY_CURRENT_USER\SOFTWARE\Echo" /v Restore /t Reg_DWORD /d "1" /f >nul)
if %SettingsItem% lss 5 goto Settings

if "%SettingsPage%"=="4" (
for %%i in (Res DSCP staticip Mouse) do (set %%i=off & for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v %%i') do if "%%a"=="0x1" set %%i=on) >nul 2>&1
echo                       OPTIONAL
echo.
echo [[94m1[91m] Static IP [32m!staticip![91m
echo Turn this on to enable Static IP
echo.
echo [[94m2[91m] Timer Resolution [32m!Res![91m
echo Turn this on for older games
echo.
echo [[94m3[91m] Mouse Optimization [32m!Mouse![91m
echo Turn this off if you use a trackpad
echo.
echo [[94m4[91m] DSCP Value [32m!DSCP![91m
echo Turn this on to prioritize your packets
echo.
choice /c:1234NB /n /m "%BS%                [N] Next   [B] Back"
set SettingsItem=!errorlevel!
if "!SettingsItem!"=="5" (set SettingsPage=1)
cls
)

if "%SettingsItem%"=="1" if "%staticip%"=="on" (Reg add "HKCU\Software\Echo" /v staticip /t Reg_DWORD /d "0" /f >nul) else (Reg add "HKCU\Software\Echo" /v staticip /t Reg_DWORD /d "1" /f >nul)
if "%SettingsItem%"=="2" if "%Res%"=="on" (Reg add "HKCU\Software\Echo" /v Res /t Reg_DWORD /d "0" /f >nul) else (Reg add "HKCU\Software\Echo" /v Res /t Reg_DWORD /d "1" /f >nul)
if "%SettingsItem%"=="3" if "%Mouse%"=="on" (Reg add "HKCU\Software\Echo" /v Mouse /t Reg_DWORD /d "0" /f >nul) else (Reg add "HKCU\Software\Echo" /v Mouse /t Reg_DWORD /d "1" /f >nul)
if "%SettingsItem%"=="4" if "%DSCP%"=="on" (Reg add "HKCU\Software\Echo" /v DSCP /t Reg_DWORD /d "0" /f >nul) else (Reg add "HKCU\Software\Echo" /v DSCP /t Reg_DWORD /d "1" /f >nul)
if "%SettingsItem%"=="5" goto Settings
if %SettingsItem% lss 5 goto Settings
goto home

:gameBooster
cls & echo Select the game location
set dialog="about:<input type=file id=FILE><script>FILE.click();new ActiveXObject
set dialog=%dialog%('Scripting.FileSystemObject').GetStandardStream(1).WriteLine(FILE.value);
set dialog=%dialog%close();resizeTo(0,0);</script>"
for /f "tokens=* delims=" %%p in ('mshta.exe %dialog%') do set "file=%%p"

if "%file%"=="" goto:eof

for %%F in ("%file%") do (cls
::GPU High Performance
Reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "%%F" /t Reg_SZ /d "GpuPreference=2;" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo GPU High Performance

::Disable Fullscreen Optimizations
Reg add "HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "%%F" /t Reg_SZ /d "~ DISABLEDXMAXIMIZEDWINDOWEDMODE" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable Fullscreen Optimizations

::High CPU Class
Reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\%%~nxF\PerfOptions" /v "CpuPriorityClass" /t Reg_DWORD /d "3" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo CPU High Class 
)
echo.
choice /c:"CQ" /n /m "%BS%               [C] Continue  [Q] Quit" & if !errorlevel! equ 2 exit /b
goto:eof

:Optimize
call:GrabSettings

if not "%NVCP%"=="0x1" if "%NvidiaDriverVersion%" equ "457.30" (
if not exist "%temp%\EchoProfile.nip" (
echo Downloading Nvidia Nip [...]
if exist "%appdata%\.minecraft\options.txt" (set DL=https://cdn.discordapp.com/attachments/798190447117074473/880931795632271390/Minecraft.nip) else (set DL=https://cdn.discordapp.com/attachments/798190447117074473/891526556692938774/EchoProfile.nip)
set DL=https://cdn.discordapp.com/attachments/798190447117074473/880931795632271390/Minecraft.nip
if exist "%windir%\system32\windowspowershell\v1.0\powershell.exe" (powershell wget !DL! -OutFile "%temp%\EchoProfile.nip") else (bitsadmin /transfer "" !DL! "%temp%\EchoProfile.nip")
)
if not exist "%temp%\EchoNvidia.exe" (
echo Downloading Nvidia Inspector [...]
set DL=https://cdn.discordapp.com/attachments/798190447117074473/829143545083461672/EchoProfile.exe
if exist "%windir%\system32\windowspowershell\v1.0\powershell.exe" (powershell wget !DL! -OutFile "%temp%\EchoNvidia.exe") else (bitsadmin /transfer "" !DL! "%temp%\EchoNvidia.exe")
)
)

if not exist "%SystemDrive%\EchoRes.exe" (if "%Res%"=="0x1" (
echo Downloading Timer Resolution [...]
::vcredist.exe /ai /passive
set DL=https://cdn.discordapp.com/attachments/798190447117074473/829143531414749195/EchoRes.exe
if exist "%windir%\system32\windowspowershell\v1.0\powershell.exe" (powershell wget !DL! -OutFile "%SystemDrive%\EchoRes.exe") else (bitsadmin /transfer "" !DL! "%SystemDrive%\EchoRes.exe")
))

::Restore Point
if not "%Restore%"=="0x1" (cls
echo Creating System Restore Point [...]
Reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "SystemRestorePointCreationFrequency" /t REG_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
powershell -ExecutionPolicy Bypass -Command "Checkpoint-Computer -Description 'Echo Optimization' -RestorePointType 'MODIFY_SETTINGS'"
if !errorlevel! neq 0 cls & echo Failed to create a restore point! & echo. & echo Press any key to continue anyway & pause >nul
)

::Registry Backup
if not exist "%SystemDrive%\Regbackup.Reg" (
call:EchoXLogo
echo.
echo %BS%           Creating Registry Backup [...]
Regedit /e "%SystemDrive%\Regbackup.Reg" >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
if !errorlevel! neq 0 cls & echo Failed to create a registry backup! & echo. & echo Press any key to continue anyway & pause >nul
)

::BCD Backup
if not exist "%SystemDrive%\bcdbackup.bcd" (
call:EchoXLogo
echo.
echo %BS%           Creating BCD Edit Backup [...]
bcdedit /export "%SystemDrive%\bcdbackup.bcd" >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
)

::Fix System Files
rem sfc /scannow
rem Dism /Online /Cleanup-Image /RestoreHealth

::Optimize Drives
rem defrag /C /O

::::::::::::::::::::::
::Win  Optimizations::
::::::::::::::::::::::
cls
title Win Optimizations
echo                  [32mWin Optimizations[91m

::Animations
if "%Animations%" equ "0x0" (
  Reg delete "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\DWM" /v "DisallowAnimations" /f >nul 2>&1
  Reg delete "HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /f >nul 2>&1
  Reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
  Reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
  Reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9e3e078012000000" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
  echo Enabled Animations
)
if "%Animations%" equ "0x1" (
  Reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\DWM" /v "DisallowAnimations" /t REG_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
  Reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t REG_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
  Reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t REG_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
  Reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d "3" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
  Reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t REG_BINARY /d "9012038010000000" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
  echo Disabled Animations
)

::Disable FTH
Reg delete "HKLM\SOFTWARE\Microsoft\FTH\State" /f >nul 2>&1
Reg add "HKLM\Software\Microsoft\FTH" /v "Enabled" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable FTH

::FSO
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d "2" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
reg add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
reg add "HKCU\System\GameConfigStore" /v "GameDVR_EFSEFeatureFlags" /t REG_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disabled FSO

::Auto restart Powershell on error
Reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "AutoRestartShell" /t REG_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"

::System responsiveness, PanTeR Said to use 14 (20 hexa)
Reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t Reg_DWORD /d "20" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo System Responsivness

::Wallpaper quality 100%
Reg add "HKCU\Control Panel\Desktop" /v "JPEGImportQuality" /t Reg_DWORD /d "100" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Wallpaper Quality

::Windows Defender
::Start "" /wait "%temp%\NSudo.exe" -U:T -P:E -M:S -ShowWindowMode:Hide cmd /c "sc config WinDefend start= disabled"
::Start "" /wait "%temp%\NSudo.exe" -U:T -P:E -M:S -ShowWindowMode:Hide cmd /c "sc stop WinDefend"
::Start "" /wait "%temp%\NSudo.exe" -U:T -P:E -M:S -ShowWindowMode:Hide cmd /c "sc config WinDefend start= auto"
::Start "" /wait "%temp%\NSudo.exe" -U:T -P:E -M:S -ShowWindowMode:Hide cmd /c "sc start WinDefend"

::Wait time to kill app during shutdown
Reg add "HKCU\Control Panel\Desktop" /v "WaitToKillAppTimeout" /t Reg_SZ /d "1000" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
::Wait to end service at shutdown
Reg add "HKLM\System\CurrentControlSet\Control" /v "WaitToKillServiceTimeout" /t Reg_SZ /d "1000" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
::Wait to kill non-responding app
Reg add "HKCU\Control Panel\Desktop" /v "HungAppTimeout" /t Reg_SZ /d "1000" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Speedup app shutdown

::Power Plan
::Import Windows Ultimate PowerPlan
powercfg /delete 88888888-8888-8888-8888-888888888888 >nul 2>&1
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 88888888-8888-8888-8888-888888888888 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
powercfg /setactive 88888888-8888-8888-8888-888888888888 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
::Import Pow Under 9
powercfg /delete 99999999-9999-9999-9999-999999999999 >nul 2>&1
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 99999999-9999-9999-9999-999999999999 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
powercfg /setactive 99999999-9999-9999-9999-999999999999 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
powercfg /delete 88888888-8888-8888-8888-888888888888 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
set EchoXPowName=EchoX
rem powercfg /powerthrottling disable /path "%temp%\EchoPow.pow" >nul 2>&1
echo Power Plan

::Require a password on wakeup: OFF
powercfg -setacvalueindex scheme_current sub_none 0E796BDB-100D-47D6-A2D5-F7D2DAA51F51 0

::Allow Throttle States: OFF
powercfg /setacvalueindex scheme_current sub_processor 3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb 0

::USB 3 Link Power Management: OFF 
powercfg -setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0

::Device Idle Policy Power Savings
powercfg -setacvalueindex scheme_current sub_none 4faab71a-92e5-4726-b531-224559672d19 1 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"

::Device Idle Policy Performance
powercfg -setacvalueindex scheme_current sub_none 4faab71a-92e5-4726-b531-224559672d19 0 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"

if "%Idle%"=="0x1" (
set EchoXPowName=%EchoXPowName% DIdle
::Disable Idle
powercfg /setacvalueindex scheme_current sub_processor 5d76a2ca-e8c0-402f-a133-2158492d58ad 1 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable Idle
) else (
::Enable Idle
powercfg -setacvalueindex scheme_current sub_processor 5d76a2ca-e8c0-402f-a133-2158492d58ad 0 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Enable Idle
)

if "%MaxPow%"=="0x1" (
set EchoXPowName=%EchoXPowName% MAX
::1/1 Increase Decrease
powercfg -setacvalueindex scheme_current sub_processor 06cadf0e-64ed-448a-8927-ce7bf90eb35d 1 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
powercfg -setacvalueindex scheme_current sub_processor 12a0ab44-fe28-4fa9-b3bd-4b64f44960a6 1 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo 1/1 Increase Decrease
::100/100 Promote Demote
powercfg -setacvalueindex scheme_current sub_processor 7b224883-b3cc-4d79-819f-8374152cbe7c 100 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
powercfg -setacvalueindex scheme_current sub_processor 4b92d758-5a24-4851-a470-815d78aee119 100 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo 100/100 Promote Demote
) else (
::30/10 Increase Decrease
powercfg -setacvalueindex scheme_current sub_processor 06cadf0e-64ed-448a-8927-ce7bf90eb35d 30 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
powercfg -setacvalueindex scheme_current sub_processor 12a0ab44-fe28-4fa9-b3bd-4b64f44960a6 10 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo 30/10 Increase Decrease
::60/40 Promote Demote
powercfg -setacvalueindex scheme_current sub_processor 7b224883-b3cc-4d79-819f-8374152cbe7c 60 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
powercfg -setacvalueindex scheme_current sub_processor 4b92d758-5a24-4851-a470-815d78aee119 40 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo 60/40 Promote Demote
)

::Apply
powercfg -setactive scheme_current >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
powercfg /changename scheme_current "%EchoXPowName%" "For EchoX Optimizer %Version% (dsc.gg/EchoX) By UnLovedCookie" >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"

if "%Throttling%"=="0x1" (
::Enable Power Throttling
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Enable Power Throttling
) else (
::Disable Power Throttling
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable Power Throttling
)

::Disable Application Telemetry
Reg add "HKLM\Software\Policies\Microsoft\Windows\AppCompat" /v "AITEnable" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
::Disable Telemetry
Reg add "HKLM\System\CurrentControlSet\Services\DiagTrack" /v "Start" /t Reg_DWORD /d "4" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable Telemetry

::Disable Biometrics
Reg add "HKLM\Software\Policies\Microsoft\Biometrics" /v "Enabled" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable Biometrics

::Security Tweaks 
::PATCH V-220930 (From Zeta)
Reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Lsa" /v "RestrictAnonymous" /t REG_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
::PATCH V-220929 (From Zeta)
Reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Lsa" /v "RestrictAnonymousSAM" /t REG_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
::Disable NetBIOS, can be exploited and is highly vulnerable. (From Zeta)
sc stop lmhosts >nul 2>&1
sc config lmhosts start=disabled >nul 2>&1
::https://cyware.com/news/what-is-smb-vulnerability-and-how-it-was-exploited-to-launch-the-wannacry-ransomware-attack-c5a97c48
sc stop LanmanWorkstation >nul 2>&1
sc config LanmanWorkstation start=disabled >nul 2>&1
echo Security Tweaks

::Unneeded Files
del /s /f /q "%SystemDrive%\windows\history\*" >nul 2>&1
del /s /f /q "%SystemDrive%\windows\recent\*" >nul 2>&1
del /s /f /q "%SystemDrive%\windows\spool\printers\*" >nul 2>&1
del /s /f /q "%SystemDrive%\Windows\Prefetch\*" >nul 2>&1
echo Cleaned Driver

::::::::::::::::::::::
::Remove Mitigations::
::::::::::::::::::::::
cls
title Remove Mitigation
echo                  [32mRemove Mitigations[91m

::Disable Process Mitigations
Reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe" /v MitigationAuditOptions /t Reg_BINARY /d "222222222222222222222222222222222222222222222222" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe" /v MitigationOptions /t Reg_BINARY /d "222222222222222222222222222222222222222222222222" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable Process Mitigations

::Disable Dma Remapping
Reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\DmaGuard\DeviceEnumerationPolicy" /v "value" /t REG_DWORD /d "2" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
for /f "tokens=1" %%i in ('driverquery') do reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%i\Parameters" /v "DmaRemappingCompatible" /t REG_DWORD /d "0" /f >nul 2>&1
echo Disable DmaRemapping

::CPU
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DistributeTimers" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"

::Disable SEHOP
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DisableExceptionChainValidation" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "KernelSEHOPEnabled" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable SEHOP

::Disable ASLR
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "MoveImages" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt" 
echo Disable ASLR

::Disable Spectre And Meltdown
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettings /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t Reg_DWORD /d "3" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t Reg_DWORD /d "3" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
del /f /q "%WinDir%\System32\mcupdate_GenuineIntel.dll" >nul 2>&1
del /f /q "%WinDir%\System32\mcupdate_AuthenticAMD.dll" >nul 2>&1
echo Disabled Spectre And Meltdown

::Disable CFG Lock
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnableCfg" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable CFG Lock

::Disable NTFS/ReFS and FS Mitigations
Reg add "HKLM\System\CurrentControlSet\Control\Session Manager" /v "ProtectionMode" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable NTFS/ReFS and FS Mitigations

::::::::::::::::::::::
::RAM  Optimizations::
::::::::::::::::::::::
cls
title RAM Optimizations
echo                  [32mRAM  Optimizations[91m


::Storage Optimizations + Ram

::Disallow drivers to get paged into virtual memory
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
::Disable Paging Combining
Reg add "HKLM\SYSTEM\currentcontrolset\control\session manager\Memory Management" /v "DisablePagingCombining" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable Paging Combining

::Set SvcSplitThreshold (revision)
set /a ram=%mem% + 1024000
Reg add "HKLM\System\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t Reg_DWORD /d "%ram%" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo SvcSplitThreshold

::Use Large System Cache to improve microstuttering
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Enable Large System Cache

::Unload .dll to Free Memory
Reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "AlwaysUnloadDLL" /t REG_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Unload .dll to Free Memory

if exist "%windir%\System32\fsutil.exe" (
::Raise the limit of paged pool memory
fsutil behavior set memoryusage 2
::https://www.serverbrain.org/solutions-2003/the-mft-zone-can-be-optimized.html
fsutil behavior set mftzone 2
echo Memory Optimizations
::HDD + SSD
fsutil behavior set disabledeletenotify 0
fsutil behavior set encryptpagingfile 0
::https://ttcshelbyville.wordpress.com/2018/12/02/should-you-disable-8dot3-for-performance-and-security/
fsutil behavior set disable8dot3 1
::Disable NTFS compression
fsutil behavior set disablecompression 1
::Disable Last Access information on directories, performance/privacy
if "!storageType!" neq "!storageType:SSD=!" fsutil behavior set disableLastAccess 0
if "!storageType!" neq "!storageType:HDD=!" fsutil behavior set disableLastAccess 1
echo HDD + SSD Optimizations
) >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"

::Optimize NTFS
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v "NTFSDisable8dot3NameCreation" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v "NTFSDisableLastAccessUpdate" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo NTFS Optimizations

::Disabling random drivers verification.
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v "DontVerifyRandomDrivers" /t REG_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
::Disable file paths exceeding 260 characters.
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v "LongPathsEnabled" /t REG_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disk Optimizations

::Disable Prefetch
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnableSuperfetch" /t REG_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "EnablePrefetcher" /t REG_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableBoottrace" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable Prefetch

::Disable Startup Apps
rem del /f /q "%appdata%\Microsoft\Windows\Start Menu\Programs\Startup\*.*" >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
rem echo Disable Start Up Programs

::Background Apps
Reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\Software\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t Reg_DWORD /d "2" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BackgroundAppGlobalToggle" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable Background Apps

::Disable Memory Compression and Page Combining
powershell -NoProfile -Command "Disable-MMAgent -mc -PageCombining"
echo Disable Memory Compression and Page Combining

::::::::::::::::::::::
::GPU  Optimizations::
::::::::::::::::::::::
cls
title GPU Optimizations
echo                  [32mGPU  Optimizations[91m

::Disable Display Scaling Credits to Zusier
if "%DisplayScaling%" equ "0x1" for /f %%i in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /s /f Scaling') do set "str=%%i" & if "!str!" neq "!str:Configuration\=!" (
	Reg add "%%i" /v "Scaling" /t REG_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
  echo Disable Display Scaling
)

::https://docs.microsoft.com/en-us/windows-hardware/drivers/display/gdi-hardware-acceleration
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "KMD_EnableGDIAcceleration" >nul 2>&1
if "%errorlevel%" equ "0" Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "KMD_EnableGDIAcceleration" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
::Enable Hardware Accelerated Scheduling
reg query "HKLM\System\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" >nul 2>&1
if "%errorlevel%" equ "0" Reg add "HKLM\System\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t Reg_DWORD /d "2" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Enable Hardware Accelerated Scheduling

::GPU
for /f "tokens=2 delims==" %%a in ('wmic path Win32_VideoController get VideoProcessor /value') do (
	for %%n in (GeForce NVIDIA RTX GTX) do echo %%a | find "%%n" >nul && goto :NVIDIA
	for %%n in (AMD Ryzen) do echo %%a | find "%%n" >nul && goto :AMD
	for %%n in (Intel UHD) do echo %%a | find "%%n" >nul && goto :INTEL
)
goto :gpuUndefined

:NVIDIA
::Enable GameMode
Reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Echo Enable Gamemode

::Nvidia Reg
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "TCCSupported" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKCU\Software\NVIDIA Corporation\Global\NVTweak\Devices\509901423-0\Color" /v "NvCplUseColorCorrection" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "PlatformSupportMiracast" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak" /v "DisplayPowerSaving" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "DisableWriteCombining" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Nvidia Reg

::Opt out of nvidia telemetry
reg add "HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /t REG_DWORD /d 0 /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v "EnableRID44231" /t REG_DWORD /d 0 /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v "EnableRID64640" /t REG_DWORD /d 0 /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\FTS" /v "EnableRID66610" /t REG_DWORD /d 0 /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\FTS" /v "EnableRID61684" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "NvBackend" /f >nul 2>nul
echo Opt out of nvidia telemtry 

::Unrestricted Clocks
set cdCache=%cd%
cd "%SystemDrive%\Program Files\NVIDIA Corporation\NVSMI\" >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
start "" /I /WAIT /B "nvidia-smi" -acp 0 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
if %errorlevel% equ 0 (echo Unrestricted Clocks)
cd %cdCache%

::OC Scanner Fix, cuz why not?
if not exist "%SystemDrive%\Program Files\NVIDIA Corporation\NVSMI" mkdir "%SystemDrive%\Program Files\NVIDIA Corporation\NVSMI" >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
copy /Y "%windir%\system32\nvml.dll" "%SystemDrive%\Program Files\NVIDIA Corporation\NVSMI\nvml.dll" >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo OC Scanner Fix

::Disable GpuEnergyDrv
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\GpuEnergyDrv" /v "Start" /t Reg_DWORD /d "4" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\GpuEnergyDr" /v "Start" /t Reg_DWORD /d "4" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable GpuEnergyDrv

::Enable Tiled Display
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "EnableTiledDisplay" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
if exist "%windir%\system32\wbem\WMIC.exe" for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID') do (
set "str=%%i" & if "!str:PCI\VEN_=!" neq "!str!" for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%i" /v "Driver"') do Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "EnableTiledDisplay" /t REG_DWORD /d "0" /f
) >nul 2>&1
echo Enable Tiled Display

::Disable Preemption
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "DisablePreemption" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "DisableCudaContextPreemption" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" /v "EnablePreemption" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "EnableCEPreemption" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "DisablePreemptionOnS3S4" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v "ComputePreemption" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable Preemption

::Disable HDCP
for /f %%i in ('Reg query "HKLM\System\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /t REG_SZ /s /e /f "NVIDIA" ^| findstr "HKEY"') do Reg add "%%a" /v "RMHdcpKeyglobZero" /t REG_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable HDCP

::Force contiguous memory allocation
for /f %%i in ('Reg query "HKLM\System\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /t REG_SZ /s /e /f "NVIDIA" ^| findstr "HKEY"') do Reg add "%%i" /v "PreferSystemMemoryContiguous" /t REG_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Force contiguous memory allocation

::PStates 0 Credits to Timecard & Zusier
::https://github.com/djdallmann/GamingPCSetup/tree/master/CONTENT/RESEARCH/WINDRIVERS#q-is-there-a-registry-setting-that-can-force-your-display-adapter-to-remain-at-its-highest-performance-state-pstate-p0
if "%pstates%" equ "0x1" for /f %%i in ('Reg query "HKLM\System\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /t REG_SZ /s /e /f "NVIDIA" ^| findstr "HKEY"') do Reg add "%%i" /v "DisableDynamicPstate" /t REG_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
if "%pstates%" equ "0x1" echo PStates 0

::kboost
if "%KBoost%"=="0x1" for /f %%i in ('Reg query "HKLM\System\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /t REG_SZ /s /e /f "NVIDIA" ^| findstr "HKEY"') do (
Reg add "%%i" /v "PowerMizerEnable" /t Reg_DWORD /d "1" /f
Reg add "%%i" /v "PowerMizerLevel" /t Reg_DWORD /d "1" /f
Reg add "%%i" /v "PowerMizerLevelAC" /t Reg_DWORD /d "1" /f
Reg add "%%i" /v "PerfLevelSrc" /t REG_DWORD /d "8738" /f
) >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
if "%KBoost%"=="0x1" echo KBoost

::NVCP
if not "%NVCP%" == "0x1" if "%NvidiaDriverVersion%" == "457.30" (
"%temp%\EchoNvidia.exe" "%temp%\EchoProfile.nip" >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo NVCP Settings
) >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
goto gpuUndefined

:AMD
::Disable Gamemode
Reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t Reg_DWORD /d "0" /f >nul
Reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t Reg_DWORD /d "0" /f >nul
echo Disable Gamemode

::Unixcorn AMD Reg Keys
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "3D_Refresh_Rate_Override_DEF" /t Reg_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "3to2Pulldown_NA" /t Reg_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "AAF_NA" /t Reg_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "Adaptive De-interlacing" /t Reg_DWORD /d "1" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "AllowRSOverlay" /t Reg_SZ /d "false" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "AllowSkins" /t Reg_SZ /d "false" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "AllowSnapshot" /t Reg_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "AllowSubscription" /t Reg_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "AntiAlias_NA" /t Reg_SZ /d "0" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "AreaAniso_NA" /t Reg_SZ /d "0" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "ASTT_NA" /t Reg_SZ /d "0" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "AutoColorDepthReduction_NA" /t Reg_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "DisableSAMUPowerGating" /t Reg_DWORD /d "1" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "DisableUVDPowerGatingDynamic" /t Reg_DWORD /d "1" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "DisableVCEPowerGating" /t Reg_DWORD /d "1" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "EnableAspmL0s" /t Reg_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "EnableAspmL1" /t Reg_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "EnableUlps" /t Reg_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "EnableUlps_NA" /t Reg_SZ /d "0" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "KMD_DeLagEnabled" /t Reg_DWORD /d "1" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "KMD_FRTEnabled" /t Reg_DWORD /d "0" /f >nul 2>&1

::AMD Tweaks
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "DisableDMACopy" /t Reg_DWORD /d "1" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "DisableBlockWrite" /t Reg_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "StutterMode" /t Reg_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "EnableUlps" /t Reg_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "PP_SclkDeepSleepDisable" /t Reg_DWORD /d "1" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "PP_ThermalAutoThrottlingEnable" /t Reg_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "DisableDrmdmaPowerGating" /t Reg_DWORD /d "1" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "KMD_EnableComputePreemption" /t Reg_DWORD /d "0" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000\UMD" /v "Main3D_DEF" /t Reg_SZ /d "1" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000\UMD" /v "Main3D" /t Reg_BINARY /d "3100" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000\UMD" /v "FlipQueueSize" /t Reg_BINARY /d "3100" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000\UMD" /v "ShaderCache" /t Reg_BINARY /d "3200" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000\UMD" /v "Tessellation_OPTION" /t Reg_BINARY /d "3200" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000\UMD" /v "Tessellation" /t Reg_BINARY /d "3100" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000\UMD" /v "VSyncControl" /t Reg_BINARY /d "3000" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000\UMD" /v "TFQ" /t Reg_BINARY /d "3200" /f >nul 2>&1
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000\DAL2_DATA__2_0\DisplayPath_4\EDID_D109_78E9\Option" /v "ProtectionControl" /t Reg_BINARY /d "0100000001000000" /f >nul 2>&1
echo AMD Reg Keys

::Melody AMD Tweaks
for %%i in (LTRSnoopL1Latency LTRSnoopL0Latency LTRNoSnoopL1Latency LTRMaxNoSnoopLatency KMD_RpmComputeLatency
        DalUrgentLatencyNs memClockSwitchLatency PP_RTPMComputeF1Latency PP_DGBMMMaxTransitionLatencyUvd
        PP_DGBPMMaxTransitionLatencyGfx DalNBLatencyForUnderFlow DalDramClockChangeLatencyNs
        BGM_LTRSnoopL1Latency BGM_LTRSnoopL0Latency BGM_LTRNoSnoopL1Latency BGM_LTRNoSnoopL0Latency
        BGM_LTRMaxSnoopLatencyValue BGM_LTRMaxNoSnoopLatencyValue) do Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "%%i" /t Reg_DWORD /d "1" /f >nul 2>&1
) >nul 2>&1

echo Optimized AMD GPU

:INTEL
::Intel iGPU tweaks
for /f %%i in ('Reg query "HKLM\System\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /t REG_SZ /s /e /f "Intel" ^| findstr "HKEY"') do (
    Reg add "%%i" /v "Disable_OverlayDSQualityEnhancement" /t REG_DWORD /d "1" /f
    Reg add "%%i" /v "IncreaseFixedSegment" /t REG_DWORD /d "1" /f
    Reg add "%%i" /v "AdaptiveVsyncEnable" /t REG_DWORD /d "0" /f
    Reg add "%%i" /v "DisablePFonDP" /t REG_DWORD /d "1" /f
    Reg add "%%i" /v "EnableCompensationForDVI" /t REG_DWORD /d "1" /f
    Reg add "%%i" /v "NoFastLinkTrainingForeDP" /t REG_DWORD /d "0" /f
    Reg add "%%i" /v "ACPowerPolicyVersion" /t REG_DWORD /d "16898" /f
    Reg add "%%i" /v "DCPowerPolicyVersion" /t REG_DWORD /d "16642" /f
) >nul 2>&1
echo Intel iGPU tweaks

::DedicatedSegmentSize in Intel iGPU
reg query "HKLM\SOFTWARE\Intel\GMM" /v "DedicatedSegmentSize" >nul 2>&1
if %ERRORLEVEL% equ 0 (
  reg add "HKLM\SOFTWARE\Intel\GMM" /v "DedicatedSegmentSize" /t REG_DWORD /d "1024" /f >nul 2>&1
  echo DedicatedSegmentSize in Intel iGPU
)

echo Optimized INTEL iGPU
:gpuUndefined

::::::::::::::::::::::
::CPU  Optimizations::
::::::::::::::::::::::
cls
title CPU Optimizations
echo                  [32mCPU  Optimizations[91m
::Disable Hibernation + Fast Startup
powercfg /h off >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v "HiberbootEnabled" /t REG_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable Hibernation

::Set Win32PrioritySeparation 26 hex/38 dec
Reg add "HKLM\System\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t Reg_DWORD /d "38" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Win32PrioritySeparation

::Reliable Timestamp
Reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Reliability" /v "TimeStampInterval" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Reliability" /v "IoPriority" /t Reg_DWORD /d "3" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Timestamp Interval

::::::::::::::::::::::
::Late Optimizations::
::::::::::::::::::::::
cls
title Late Optimizations
echo                  [32mLate Optimizations[91m

::MMCSS
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\MMCSS" /v "Start" /t Reg_DWORD /d "4" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t Reg_DWORD /d "8" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t Reg_DWORD /d "6" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t Reg_SZ /d "High" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t Reg_SZ /d "High" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo MMCCSS

::Windows 10+8 
::100%
::Scale 1-to-1
if "%Mouse%" equ "0x1" (
Reg add "HKCU\Control Panel\Mouse" /v "MouseSensitivity" /t Reg_SZ /d "10" /f
Reg add "HKU\.DEFAULT\Control Panel\Mouse" /v "MouseSpeed" /t Reg_SZ /d "0" /f
Reg add "HKU\.DEFAULT\Control Panel\Mouse" /v "MouseThreshold1" /t Reg_SZ /d "0" /f
Reg add "HKU\.DEFAULT\Control Panel\Mouse" /v "MouseThreshold2" /t Reg_SZ /d "0" /f
Reg add "HKCU\Control Panel\Mouse" /v "SmoothMouseXCurve" /t REG_BINARY /d 0000000000000000C0CC0C0000000000809919000000000040662600000000000033330000000000 /f
Reg add "HKCU\Control Panel\Mouse" /v "SmoothMouseYCurve" /t REG_BINARY /d 0000000000000000000038000000000000007000000000000000A800000000000000E00000000000 /f
echo Mouse Acc

rem Missing
echo Windows Scaling
) >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"

::CSRSS priority
::csrss is responsible for mouse input, setting to high may yield an improvement in input latency.
Reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v CpuPriorityClass /t Reg_DWORD /d "4" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v IoPriority /t Reg_DWORD /d "3" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo CSRSS priority

if not exist "%windir%\system32\wbem\WMIC.exe" (goto :skipMSIandAffinites)

::DEL GPU + USB + Sata controllers Device Priority + NET (Use Normal Priority on vmware)
for /f "delims=" %%# in ('"wmic computersystem get manufacturer /format:value"') do set "%%#" >nul & if "!Manufacturer:VMWare=!" neq "!Manufacturer!" (set "VMWare= /t Reg_DWORD /d 2") else (set "VMWare=")
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID') do set "str=%%i" & if "!str:PCI\VEN_=!" neq "!str!" Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f >nul 2>nul
for /f %%i in ('wmic path Win32_USBController get PNPDeviceID') do set "str=%%i" & if "!str:PCI\VEN_=!" neq "!str!" Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f >nul 2>nul
for /f %%i in ('wmic path win32_NetworkAdapter get PNPDeviceID') do set "str=%%i" & if "!str:PCI\VEN_=!" neq "!str!" Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority"%VMWare% /f >nul 2>nul
(for /f %%i in ('wmic path Win32_IDEController get PNPDeviceID') do set "str=%%i" & if "!str:PCI\VEN_=!" neq "!str!" Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /f) >nul 2>nul
echo Delete Device Priority

::Enable MSI Mode on GPU if supported
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID') do set "str=%%i" & if "!str:PCI\VEN_=!" neq "!str!" (
Reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
if !ERRORLEVEL! EQU 0 (
Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t Reg_DWORD /d "1" /f
Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /t REG_DWORD /d "3" /f
)
) >nul 2>&1
echo GPU MSI Mode

::Enable MSI Mode on Net
for /f %%i in ('wmic path win32_NetworkAdapter get PNPDeviceID') do set "str=%%i" & if "!str:PCI\VEN_=!" neq "!str!" (
Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t Reg_DWORD /d "1" /f
Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /t REG_DWORD /d "3" /f 
) >nul 2>&1

::Enable MSI Mode on USB & Sata controllers
for /f %%i in ('wmic path Win32_USBController get PNPDeviceID') do set "str=%%i" & if "!str:PCI\VEN_=!" neq "!str!" Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t Reg_DWORD /d "1" /f >nul 2>&1
(for /f %%i in ('wmic path Win32_IDEController get PNPDeviceID') do set "str=%%i" & if "!str:PCI\VEN_=!" neq "!str!" Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t Reg_DWORD /d "1" /f) >nul 2>&1
echo CPU + NET MSI Mode

::Hyperthreading 4 Cores
if %THREADS% gtr 2 if %THREADS% lss 4 if %CORES% neq %THREADS% (
::USB Affinites
for /f %%i in ('wmic path Win32_USBController get PNPDeviceID') do set "str=%%i" & if "!str:PCI\VEN_=!" neq "!str!" (
Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePolicy" /t REG_DWORD /d "4" /f
Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "AssignmentSetOverride" /t REG_BINARY /d "C0" /f
)
::GPU Affinites
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID') do set "str=%%i" & if "!str:PCI\VEN_=!" neq "!str!" (
Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePolicy" /t REG_DWORD /d "4" /f
Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "AssignmentSetOverride" /t REG_BINARY /d "C0" /f
)
::NET Affinites
for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID') do set "str=%%i" & if "!str:PCI\VEN_=!" neq "!str!" (
Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePolicy" /t REG_DWORD /d "4" /f
Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "AssignmentSetOverride" /t REG_BINARY /d "30" /f
)
) >nul 2>&1

::No Hyperthreading 4 Cores
if %THREADS% gtr 2 if %THREADS% lss 4 if %CORES% equ %THREADS% (
::USB Affinites
for /f %%i in ('wmic path Win32_USBController get PNPDeviceID') do set "str=%%i" & if "!str:PCI\VEN_=!" neq "!str!" (
Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePolicy" /t REG_DWORD /d "4" /f
Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "AssignmentSetOverride" /t REG_BINARY /d "08" /f
)
::GPU Affinites
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID') do set "str=%%i" & if "!str:PCI\VEN_=!" neq "!str!" (
Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePolicy" /t REG_DWORD /d "4" /f
Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "AssignmentSetOverride" /t REG_BINARY /d "02" /f
)
::NET Affinites
for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID') do set "str=%%i" & if "!str:PCI\VEN_=!" neq "!str!" (
Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePolicy" /t REG_DWORD /d "4" /f
Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "AssignmentSetOverride" /t REG_BINARY /d "04" /f
)
) >nul 2>&1

::More than 4 cores Affinites
if %THREADS% gtr 4 (
::GPU AllProccessorsInMachine
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID') do set "str=%%i" & if "!str:PCI\VEN_=!" neq "!str!" (
Reg add "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePolicy" /t REG_DWORD /d "3" /f
Reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "AssignmentSetOverride" /f
)
::NET SpreadMessageAcrossAllProccessors
for /f %%i in ('wmic path win32_NetworkAdapter get PNPDeviceID') do set "str=%%i" & if "!str:PCI\VEN_=!" neq "!str!" (
Reg add "HKLM\System\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePolicy" /t Reg_DWORD /d "5" /f
Reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\Affinity Policy" /v "AssignmentSetOverride" /f
)
) >nul 2>nul
echo GPU + NET Affinites

::Remove GPU Limits
for /f %%i in ('wmic path Win32_VideoController get PNPDeviceID') do set "str=%%i" & if "!str:PCI\VEN_=!" neq "!str!" Reg delete "HKLM\SYSTEM\CurrentControlSet\Enum\%%i\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MessageNumberLimit" /f >nul 2>&1
echo Remove GPU Limits

:skipMSIandAffinites

::::::::::::::::::::::
::Bios Optimizations::
::::::::::::::::::::::
cls
title BIOS Optimizations
echo                  [32mBIOS Optimizations[91m

if "%Res%" equ "0x1" (
::Timer Resolution
bcdedit /set disabledynamictick yes >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
bcdedit /set useplatformtick yes >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
(%SystemDrive%\EchoRes.exe -install) >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
sc start STR >nul 2>&1
echo Timer Resolution
) else (
::Disable HPET
if exist "%temp%\EchoView.exe" ("%temp%\EchoView.exe" /disable "High Precision Event Timer" >nul 2>&1)
bcdedit /deletevalue useplatformclock >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
bcdedit /set disabledynamictick yes >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
powershell -NoProfile -exec bypass -Command "Get-PnpDevice | Where-Object { $_.InstanceId -like 'ACPI\PNP0103\2&daba3ff&*' } | Disable-PnpDevice -Confirm:$false"
echo Disable HPET
)

::Better Input
bcdedit /set tscsyncpolicy legacy >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo tscsyncpolicy legacy

::Quick Boot
if "%duelboot%" equ "yes" (bcdedit /timeout 0) >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
bcdedit /set bootuxdisabled On >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
bcdedit /set bootmenupolicy standard >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
bcdedit /set quietboot yes >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Quick Boot

::Disable Hyper-V
bcdedit /set hypervisorlaunchtype off >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable Hyper-V

::Windows 8 Boot Stuff
for /f "tokens=4-9 delims=. " %%i in ('ver') do set winversion=%%i.%%j
REM windows 8.1
if "!winversion!" == "6.3.9600" (
bcdedit /set {globalsettings} custom:16000067 true >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
bcdedit /set {globalsettings} custom:16000069 true >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
bcdedit /set {globalsettings} custom:16000068 true >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Windows 8 Boot Stuff
)

::nx
echo %PROCESSOR_IDENTIFIER% ^| find "Intel" >nul && bcdedit /set nx optout || bcdedit /set nx alwaysoff

::Linear Address 57
bcdedit /set linearaddress57 OptOut >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
bcdedit /set increaseuserva 268435328 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Linear Address 57

::Disable some of the kernel memory mitigations
rem Forcing Intel SGX and setting isolatedcontext to No will cause a black screen
rem bcdedit /set isolatedcontext No >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
bcdedit /set allowedinmemorysettings 0x0 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Kernel memory mitigations

::Disable DMA memory protection and cores isolation
bcdedit /set vsmlaunchtype Off >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
bcdedit /set vm No >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\Software\Policies\Microsoft\FVE" /v "DisableExternalDMAUnderLock" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\Software\Policies\Microsoft\Windows\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\Software\Policies\Microsoft\Windows\DeviceGuard" /v "HVCIMATRequired" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo DMA memory protection and cores isolation

::Enable X2Apic
bcdedit /set x2apicpolicy Enable >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
bcdedit /set uselegacyapicmode No >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Enable X2Apic

::Enable Memory Mapping for PCI-E devices
bcdedit /set configaccesspolicy Default >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
bcdedit /set MSI Default >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
bcdedit /set usephysicaldestination No >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
bcdedit /set usefirmwarepcisettings No >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Enable Memory Mapping

::::::::::::::::::::::
::TCPIP Optimization::
::::::::::::::::::::::
cls
title TCPIP Optimization
echo                  [32mTCPIP Optimization[91m

::Do not use NLA
if "%Account%" neq "MS" Reg add "HKLM\System\CurrentControlSet\Services\Tcpip\QoS" /v "Do not use NLA" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"

::Set max port to 65535
Reg add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters" /v "MaxUserPort" /t REG_DWORD /d "65534" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt" 
echo Set max port to 65535

::Reduce TIME_WAIT
Reg add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpTimedWaitDelay" /t REG_DWORD /d "30" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt" 
echo Reduce TIME_WAIT

::Disable Window Scaling Heuristics (tries to identify connectivity and throughput problems and take appropriate measures.) 
Reg add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters" /v "EnableWsd" /t REG_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt" 
echo Disable Window Scaling Heuristics

::Enable TCP Extensions for High Performance
Reg add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters" /v "Tcp1323Opts" /t REG_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"  
echo Enable TCP Extensions for High Performance

::Detect congestion fail to receive acknowledgement for a packet within the estimated timeout
Reg add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters" /v "TCPCongestionControl" /t REG_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt" 
echo Detect congestion fails

::Network Priorities
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "LocalPriority" /t Reg_DWORD /d "4" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "HostsPriority" /t Reg_DWORD /d "5" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "DnsPriority" /t Reg_DWORD /d "6" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "NetbtPriority" /t Reg_DWORD /d "7" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Network Priorities

::Enable The Network Adapter Onboard Processor
Reg add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters" /v "DisableTaskOffload" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Enable The Network Adapter Onboard Processor

::Disable NetBios
Reg add "HKLM\System\CurrentControlSet\Services\NetBT\Parameters\Interfaces" /v "NetbiosOptions" /t Reg_DWORD /d "2" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable NetBios

::Reduce Time To Live
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "DefaultTTL" /t REG_DWORD /d "64" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Reduce Time To Live

::Duplicate ACKs
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpMaxDupAcks" /t REG_DWORD /d "2" /f >nul 2>&1
::Disable SACKS
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "SackOpts" /t REG_DWORD /d "0" /f >nul 2>&1

::Disable IPv6
rem Reg add "HKLM\System\CurrentControlSet\Services\Tcpip6\Parameters" /v "DisabledComponents" /t REG_DWORD /d "4294967295" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt" 

::Disable Nagle's Algorithm
Reg add "HKLM\Software\Microsoft\MSMQ\Parameters" /v "TCPNoDelay" /t REG_DWORD /d "1" /f >nul 2>&1  
rem https://en.wikipedia.org/wiki/Nagle%27s_algorithm
for /f %%s in ('Reg query "HKLM\Software\Microsoft\Windows NT\CurrentVersion\NetworkCards" /f "ServiceName" /s') do set "str=%%i" & if "!str:ServiceName_=!" neq "!str!" (
 	Reg add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%s" /v "TCPNoDelay" /t Reg_DWORD /d "1" /f
	Reg add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%s" /v "TcpAckFrequency" /t Reg_DWORD /d "1" /f
	Reg add "HKLM\System\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%s" /v "TcpDelAckTicks" /t Reg_DWORD /d "0" /f
) >>"%temp%\EchoLog.txt" 2>>nul
echo Disable Nagle's Algorithm

::::::::::::::::::::::
::Net  Optimizations::
::::::::::::::::::::::
cls
title Network Optimizations
echo                  [32mNet Optimizations[91m

::Lanman Server
rem Reg add "HKLM\System\CurrentControlSet\Services\LanmanServer\Parameters" /v "a" /t REG_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt" 

::Set the maximum number of concurrent connections (per server endpoint) allowed when making requests using an HttpClient object.
Reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v "MaxConnectionsPerServer" /t REG_DWORD /d "16" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt" 
::Maximum number of HTTP 1.0 connections to a Web server
Reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v "MaxConnectionsPer1_0Server" /t REG_DWORD /d "16" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt" 
echo Maximum number of concurrent connections

::TCP Congestion Control/Avoidance Algorithm
Reg add "HKLM\System\CurrentControlSet\Control\Nsi\{eb004a03-9b1a-11d4-9123-0050047759bc}\0" /v "0200" /t REG_BINARY /d "0000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000ff000000000000000000000000000000000000000000ff000000000000000000000000000000" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt" 
Reg add "HKLM\System\CurrentControlSet\Control\Nsi\{eb004a03-9b1a-11d4-9123-0050047759bc}\0" /v "1700" /t REG_BINARY /d "0000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000ff000000000000000000000000000000000000000000ff000000000000000000000000000000" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt" 
echo TCP Congestion Control/Avoidance Algorithm

::Enable DNS over HTTPS
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v "EnableAutoDoh" /t REG_DWORD /d "2" /f >nul 2>&1
echo Enable DNS over HTTPS

::https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.QualityofService::QosTimerResolution
Reg add "HKLM\Software\Policies\Microsoft\Windows\Psched" /v "TimerResolution" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
Reg add "HKLM\System\CurrentControlSet\Services\AFD\Parameters" /v "DoNotHoldNicBuffers" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Qos TimerResolution

::Disable LLMNR
Reg add "HKLM\Software\Policies\Microsoft\Windows NT\DNSClient" /v "EnableMulticast" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable LLMNR

::Remove OneDrive Sync
Reg add "HKLM\Software\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t Reg_DWORD /d "1" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Remove OneDrive Sync

::Disable Delivery Optimization
Reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Settings" /v "DownloadMode" /t Reg_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Disable Delivery Optimization

::Disable limiting bandwith
::https://admx.help/?Category=Windows_10_2016&Policy=Microsoft.Policies.QualityofService::QosNonBestEffortLimit
Reg add "HKLM\Software\Policies\Microsoft\Windows\Psched" /v "NonBestEffortLimit" /t REG_DWORD /d "0" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Remove Limiting Bandwidth

::Network Throttling Index
::https://cdn.discordapp.com/attachments/890128142075850803/890135598566895666/unknown.png
Reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t Reg_DWORD /d "10" /f >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Network Throttling Index

::NIC
for /f %%i in ('wmic path Win32_NetworkAdapter get PNPDeviceID ^| findstr /L "PCI\VEN_"') do for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum\%%i" /v "Driver" ^| findstr /L "{"') do (
reg export "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" "C:\Hone\HoneRevert\ognic.reg" /y
::Disable Keys w "*"
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "*WakeOnMagicPacket" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "*WakeOnPattern" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "*FlowControl" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "*EEE" /t REG_SZ /d "0" /f
::Disable Keys wo "*"
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "EnablePME" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "WakeOnLink" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "EEELinkAdvertisement" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "ReduceSpeedOnPowerDown" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "PowerSavingMode" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "EnableGreenEthernet" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "S5WakeOnLan" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "ULPMode" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "GigaLite" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "EnableSavePowerNow" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "EnablePowerManagement" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "EnableDynamicPowerGating" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "EnableConnectedPowerGating" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "AutoPowerSaveModeEnabled" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "AutoDisableGigabit" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "AdvancedEEE" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "PowerDownPll" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "S5NicKeepOverrideMacAddrV2" /t REG_SZ /d "0" /f
::Disable JumboPacket
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "JumboPacket" /t REG_SZ /d "0" /f
::Enable RSS
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "RSS" /t REG_SZ /d "1" /f
::Interrupt Moderation Adaptive (Default)
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "ITR" /t REG_SZ /d "125" /f
::Receive/Transmit Buffers
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "ReceiveBuffers" /t REG_SZ /d "266" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "TransmitBuffers" /t REG_SZ /d "266" /f
::Disable Wake Features
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "WolShutdownLinkSpeed" /t REG_SZ /d "2" /f
::Disable LargeSendOffloads
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "LsoV2IPv4" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "LsoV2IPv6" /t REG_SZ /d "0" /f
::Disable Offloads
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "UDPChecksumOffloadIPv6" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "IPChecksumOffloadIPv4" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "UDPChecksumOffloadIPv4" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "PMARPOffload" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "PMNSOffload" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "TCPChecksumOffloadIPv4" /t REG_SZ /d "0" /f
Reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\%%a" /v "TCPChecksumOffloadIPv6" /t REG_SZ /d "0" /f
) >nul 2>&1
echo NIC

::Internet Priority
if not "%DSCP%"=="0x1" (goto :skipPriority)
Reg add "HKLM\SYSTEM\CurrentControlSet\Services\Psched" /v "Start" /t Reg_DWORD /d "1" /f >nul 2>&1
Start "" /wait "%temp%\NSudo.exe" -U:T -P:E -ShowWindowMode:Hide cmd /c sc start Psched
(powershell Get-NetAdapterQos -Name "*" ^| Enable-NetAdapterQos) >nul 2>&1
for %%i in (csgo VALORANT-Win64-Shipping javaw FortniteClient-Win64-Shipping ModernWarfare r5apex) do (
    Reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%i" /v "Application Name" /t Reg_SZ /d "%%i.exe" /f
    Reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%i" /v "Version" /t Reg_SZ /d "1.0" /f
    Reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%i" /v "Protocol" /t Reg_SZ /d "*" /f
    Reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%i" /v "Local Port" /t Reg_SZ /d "*" /f
    Reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%i" /v "Local IP" /t Reg_SZ /d "*" /f
    Reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%i" /v "Local IP Prefix Length" /t Reg_SZ /d "*" /f
    Reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%i" /v "Remote Port" /t Reg_SZ /d "*" /f
    Reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%i" /v "Remote IP" /t Reg_SZ /d "*" /f
    Reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%i" /v "Remote IP Prefix Length" /t Reg_SZ /d "*" /f
    Reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%i" /v "DSCP Value" /t Reg_SZ /d "46" /f
    Reg add "HKLM\Software\Policies\Microsoft\Windows\QoS\%%i" /v "Throttle Rate" /t Reg_SZ /d "-1" /f
) >nul 2>nul
echo Priority
:skipPriority

::Static IP Credits: Zusier
if "%staticip%" equ "0x1" (
set dns1=1.1.1.1
for /f "tokens=4" %%i in ('netsh int show interface ^| find "Connected"') do set devicename=%%i
::for /f "tokens=2 delims=[]" %%i in ('ping -4 -n 1 %ComputerName%^| findstr [') do set LocalIP=%%i
for /f "tokens=3" %%i in ('netsh int ip show config name^="%devicename%" ^| findstr "IP Address:"') do set LocalIP=%%i
for /f "tokens=3" %%i in ('netsh int ip show config name^="%devicename%" ^| findstr "Default Gateway:"') do set DHCPGateway=%%i
for /f "tokens=2 delims=()" %%i in ('netsh int ip show config name^="Ethernet" ^| findstr "Subnet Prefix:"') do for /F "tokens=2" %%a in ("%%i") do set DHCPSubnetMask=%%a
netsh int ipv4 set address name="%devicename%" static %LocalIP% %DHCPSubnetMask% %DHCPGateway%
powershell -NoProfile -Command "Set-DnsClientServerAddress -InterfaceAlias "%devicename%" -ServerAddresses %dns1%"
) >>"%temp%\EchoLog.txt" 2>>nul
if "%staticip%" equ "0x1" echo Static IP

::Netsh
netsh winsock reset >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
netsh int ip reset c:resetlog.txt >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
netsh int ip reset C:\tcplog.txt >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
netsh int tcp set supplemental Internet congestionprovider=ctcp >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
netsh int tcp set heuristics disabled >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
netsh int tcp set global initialRto=2000 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
netsh int tcp set global autotuninglevel=normal >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
netsh int tcp set global rsc=disabled >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
netsh int tcp set global chimney=disabled >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
netsh int tcp set global dca=enabled >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
netsh int tcp set global netdma=disabled >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
netsh int tcp set global ecncapability=enabled >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
netsh int tcp set global timestamps=disabled >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
netsh int tcp set global nonsackrttresiliency=disabled >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
netsh int tcp set global rss=enabled >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
netsh int tcp set global MaxSynRetransmissions=2 >>"%temp%\EchoLog.txt" 2>>"%temp%\EchoError.txt"
echo Netsh

title EchoX
rundll32 user32.dll,MessageBeep
call:EchoXLogo
rem for /f "delims=" %%i in (%temp%\EchoError.txt) do set "EchoError=%%i" & if "%EchoError: =%" neq "BeginErrorLog" (echo %BS%     There was a error while applying Echo...) else (echo %BS%       Optimizations Finished)
echo %BS%       Optimizations Finished
echo %BS%             Restart to fully apply...
echo.
echo.
choice /c:"BQS" /n /m "%BS%       [Q] Quit   [S] Soft-Restart   [B] Back"
if %errorlevel% equ 2 exit /b
if %errorlevel% equ 3 call:softRestart
goto Home

:softRestart
cls
echo Restarting Explorer [...]
>nul 2>&1 taskkill /F /IM explorer.exe && start /wait explorer.exe
echo Refreshing Internet [...]
::Release the current IP address obtains a new one.
echo ipconfig /release >"%temp%\RefreshNet.bat"
echo ipconfig /renew >>"%temp%\RefreshNet.bat"
::Delete and reacquire the hostname.
echo arp -d * >>"%temp%\RefreshNet.bat"
::Purge and reload the remote cache name table.
echo nbtstat -R >>"%temp%\RefreshNet.bat"
::Sends Name Release packets to WINS and then refreshes.
echo nbtstat -RR >>"%temp%\RefreshNet.bat"
::Flush the DNS and Begin manual dynamic registration for DNS names and IP addresses.
echo ipconfig /flushdns >>"%temp%\RefreshNet.bat"
echo ipconfig /registerdns >>"%temp%\RefreshNet.bat"
Start "" /wait "%temp%\NSudo.exe" -U:T -P:E -M:S -ShowWindowMode:Hide -wait cmd /c "%temp%\RefreshNet.bat"
echo Restarting Graphics Driver [...]
Start "" /wait "%temp%\Restart64.exe"
goto:eof

:Undo
cls
echo.
echo How to revert changes:
echo.
echo.
echo 1. Hold shift and press restart
echo 2. Find Command Prompt
echo 3. Type a letter and a hyphen e.g. "C:" or "E:"
echo 4. Type "dir"
echo 5. If Regbackup isnt listed,
echo    Go back to step 3 using another letter
echo 6. Type Regedit.exe /s "Regbackup"
echo 7. Type bcdedit.exe /import "bcdbackup"
echo.
echo.
choice /c:QB /n /m "%BS%                [Q] Quit   [B] Back" & if !errorlevel! equ 1 exit /b
goto :Home

:Credits
cls
echo           Zusier - Debloat + Network + More
echo            Couleur - App and Game Settings
echo              Uwe Sieber - Device Cleaner
echo               Melody - Pagefile and AMD
echo               Matishzz - AMD and Device
echo                EverythingTech - Helped
echo                AuraSide Inc. - Debloat
echo                 Orbmu2k - NVInspector
echo                 Mark Cranness - Mouse
echo                  mbk1969 - Timer Res
echo                  yungkkj - Powerplan
echo                    M2Teams - NSudo
echo                    Waffle - Helped
echo                      Vuk - Tweak
echo [===============================================P1=]
choice /c:"NB" /n /m "%BS%                 [N] Next  [B] Back"
if !errorlevel! neq 1 goto :Home
cls
echo.
echo.
echo             UnLovedCookie#6871 - Creator
echo.
echo.
echo.
echo                        Discord
echo             discord.com/invite/dptDHp9p9k
echo.
echo.
echo                        Youtube
echo   www.youtube.com/channel/UCc8L3DAQ2b9pyD7K9siHl9Q
echo.
echo.
echo [===============================================P2=]
choice /c:"NB" /n /m "%BS%                 [N] Next  [B] Back"
if !errorlevel! neq 1 goto :Home
goto :Credits

:EchoXLogo
cls
echo.
echo.
echo %BS%     ______ _____ ___ ___ _______    ___   ___
echo %BS%    ^|\   __\   ___\  \\  \\   _  \  ^|\  \ /  /^|
echo %BS%    \ \  \__\  \__^|\  \\  \\  \\  \ \ \  \  / /
echo %BS%     \ \   __\  \   \   _  \\  \\  \ \ \   / /
echo %BS%      \ \  \__\  \___\  \\  \\  \\  \ \/   \/
echo %BS%       \ \_____\______\  \\__\\______\/  \  \
echo %BS%        \^|_____^|______^|__^|^|__^|^|______/__/ \__\
echo %BS%                                     [__^|\^|__] %Version%
goto:eof

:GrabSettings
::Power
(for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v MaxPow') do set MaxPow=%%a) >nul 2>&1
(for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v Idle') do set Idle=%%a) >nul 2>&1
(for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v Throttling') do set Throttling=%%a) >nul 2>&1
(for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v pstates') do set pstates=%%a) >nul 2>&1
::Advanced
(for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v Debloat') do set Debloat=%%a) >nul 2>&1
(for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v BCD') do set BCD=%%a) >nul 2>&1
(for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v Restore') do set Restore=%%a) >nul 2>&1
(for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v KBoost') do set KBoost=%%a) >nul 2>&1
::Optional
(for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v Res') do set Res=%%a) >nul 2>&1
(for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v DSCP') do set DSCP=%%a) >nul 2>&1
(for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v DisplayScaling') do set DisplayScaling=%%a) >nul 2>&1
(for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v Mouse') do set Mouse=%%a) >nul 2>&1
::Optional PG 2
(for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v staticip') do set staticip=%%a) >nul 2>&1
(for /f "tokens=3 skip=2" %%a in ('Reg query "HKCU\Software\Echo" /v Animations') do set Animations=%%a) >nul 2>&1
goto:eof