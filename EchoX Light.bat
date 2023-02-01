@echo off
Mode 52,40
title EchoX Lite
set Version=1

::Enable Delayed Expansion
setlocal EnableDelayedExpansion

::Enable ANSI escape sequences
for /f "tokens=3" %%a in ('Reg query HKCU\CONSOLE /v VirtualTerminalLevel 2^>nul') do set /a "ANSI=%%a"
if "%ANSI%" neq "1" (
Reg add HKCU\CONSOLE /v VirtualTerminalLevel /t REG_DWORD /d 1 /f
start "" "%~s0"
exit /b
)

::Choice Prompt Setup
for /f %%A in ('"prompt $H &echo on &for %%B in (1) do rem"') do set BS=%%A

::Get Admin Rights
rmdir %SystemDrive%\Windows\system32\adminrightstest >nul 2>&1
mkdir %SystemDrive%\Windows\system32\adminrightstest >nul 2>&1
if %errorlevel% neq 0 (
powershell -NoProfile -NonInteractive -Command start -verb runas "'%~s0'" >nul 2>&1
exit /b
)

::Check For Internet
Ping www.google.nl -n 1 -w 1000 >nul
if %errorlevel% neq 0 (
echo No Internet Connection
pause
exit /b
)

::Run CMD in 32-Bit
set SystemPath=%SystemRoot%\System32
if not "%ProgramFiles(x86)%"=="" (if exist %SystemRoot%\Sysnative\* set SystemPath=%SystemRoot%\Sysnative)
if "%processor_architecture%" neq "AMD64" (start "" /I "%SystemPath%\cmd.exe" /c "%~s0" & exit /b)

::Check For Updates
curl -g -k -L -# -o "%tmp%\latestVersion.bat" "https://raw.githubusercontent.com/UnLovedCookie/EchoX/main/Files/lightVersion" >nul 2>&1
call "%tmp%\latestVersion.bat"
if "%Version%" lss "!latestVersion!" (cls
curl -L -o "%~s0" "https://github.com/UnLovedCookie/EchoX/releases/latest/download/EchoXLight.bat" >nul 2>&1
call "%~s0"
)

::NSudo
if not exist "%tmp%\NSudo.exe" (
echo Downloading NSudo [...]
curl -g -k -L -# -o "%tmp%\NSudo.exe" "https://github.com/UnLovedCookie/EchoX/raw/main/Files/NSudo.exe" >nul 2>&1
)

::Setup NSudo
Start "" /D "%tmp%" NSudo.exe -U:S -ShowWindowMode:Hide cmd /c "Reg add "HKLM\System\CurrentControlSet\Services\TrustedInstaller" /v "Start" /t REG_DWORD /d "3" /f"
Start "" /D "%tmp%" NSudo.exe -U:S -ShowWindowMode:Hide cmd /c "sc start "TrustedInstaller"

:Optimize

::Disable Power Throttling
call :ControlSet "Control\Session Manager\Power" "CoalescingTimerInterval" "0" >nul
call :ControlSet "Control\Power" "EnergyEstimationEnabled" "0" >nul
call :ControlSet "Control\Power" "EventProcessorEnabled" "0" >nul
call :ControlSet "Control\Power\PowerThrottling" "PowerThrottlingOff" "1" >nul
echo Disable Power Throttling

::Disable USB Power Savings
for /f "tokens=*" %%a in ('Reg query "HKLM\System\CurrentControlSet\Enum" /s /f "StorPort" 2^>nul ^| findstr "StorPort"') do call :CurrentControlSet "%%a" "EnableIdlePowerManagement" "0"
for /f %%a in ('wmic PATH Win32_PnPEntity GET DeviceID ^| find "USB\VID_"') do (
call :ControlSet "Enum\%%a\Device Parameters" "EnhancedPowerManagementEnabled" "0"
call :ControlSet "Enum\%%a\Device Parameters" "AllowIdleIrpInD3" "0"
call :ControlSet "Enum\%%a\Device Parameters" "EnableSelectiveSuspend" "0"
call :ControlSet "Enum\%%a\Device Parameters" "DeviceSelectiveSuspended" "0"
call :ControlSet "Enum\%%a\Device Parameters" "SelectiveSuspendEnabled" "0"
call :ControlSet "Enum\%%a\Device Parameters" "SelectiveSuspendOn" "0"
call :ControlSet "Enum\%%a\Device Parameters" "D3ColdSupported" "0"
) >nul
echo Disable USB Power Savings

::Enable FSE
Reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d "0" /f >nul
Reg add "HKCU\System\GameConfigStore" /v "AllowGameDVR" /t REG_DWORD /d "0" /f >nul
Reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d "0" /f >nul
Reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "HistoricalCaptureEnabled" /t REG_DWORD /d "0" /f >nul
Reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehavior" /t REG_DWORD /d "2" /f >nul
Reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d "2" /f >nul
Reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d "1" /f >nul
Reg add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d "1" /f >nul
Reg add "HKCU\System\GameConfigStore" /v "GameDVR_EFSEFeatureFlags" /t REG_DWORD /d "0" /f >nul
echo Enable FSE

::Disable Process Mitigations
Reg add "HKLM\System\CurrentControlSet\Control\Session Manager\kernel" /v MitigationOptions /t REG_BINARY /d 222222222222222222222222222222222222222222222222 /f >nul
Reg add "HKLM\System\ControlSet001\Control\Session Manager\kernel" /v MitigationOptions /t REG_BINARY /d 222222222222222222222222222222222222222222222222 /f >nul
Reg add "HKLM\System\ControlSet002\Control\Session Manager\kernel" /v MitigationOptions /t REG_BINARY /d 222222222222222222222222222222222222222222222222 /f >nul
echo Disable Process Mitigations

::Disable Core Isolation
call :ControlSet "Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled" "0"
Reg add "HKLM\Software\Policies\Microsoft\Windows\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d "0" /f >nul
bcdedit /set vsmlaunchtype Off >nul
bcdedit /set vm No >nul
bcdedit /set hypervisorlaunchtype off >nul
bcdedit /set isolatedcontext No >nul
bcdedit /set allowedinmemorysettings 0x0 >nul
echo Disable Core Isolation

::Disable Data Execution Prevention
Reg add "HKLM\Software\Policies\Microsoft\Internet Explorer\Main" /v "DEPOff" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\Software\Policies\Microsoft\Windows\Explorer" /v "NoDataExecutionPrevention" /t REG_DWORD /d 1 /f >nul
Reg add "HKLM\Software\Policies\Microsoft\Windows\System" /v "DisableHHDEP" /t REG_DWORD /d 1 /f >nul
echo Disable Data Execution Prevention

::Disable TsX to Mitigate ZombieLoad
call :ControlSet "Control\Session Manager\kernel" "DisableTsx" "1"
echo Disable TsX to Mitigate ZombieLoad

::Disable Dma Memory Protection
Reg add "HKLM\Software\Microsoft\PolicyManager\default\DmaGuard\DeviceEnumerationPolicy" /v "value" /t REG_DWORD /d "2" /f >nul
Reg add "HKLM\Software\Policies\Microsoft\FVE" /v "DisableExternalDMAUnderLock" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\Software\Policies\Microsoft\Windows\DeviceGuard" /v "HVCIMATRequired" /t REG_DWORD /d "0" /f >nul
echo Disable Dma Remapping / Memory Protection

::Disable SEHOP
call :ControlSet "Control\Session Manager\kernel" "DisableExceptionChainValidation" "1"
call :ControlSet "Control\Session Manager\kernel" "KernelSEHOPEnabled" "0"
echo Disable SEHOP

::Disable Control Flow Guard
call :ControlSet "Control\Session Manager\Memory Management" "EnableCfg" "0"
call :ControlSet "Control\Session Manager" "ProtectionMode" "0"
echo Disable Control Flow Guard

::Disable Spectre And Meltdown
call :ControlSet "Control\Session Manager\Memory Management" "FeatureSettings" "0"
call :ControlSet "Control\Session Manager\Memory Management" "FeatureSettingsOverride" "3"
call :ControlSet "Control\Session Manager\Memory Management" "FeatureSettingsOverrideMask" "3"
start "" /D "%tmp%" NSudo.exe -U:T -P:E -M:S -ShowWindowMode:Hide cmd /c "del /f /q %WinDir%\System32\mcupdate_GenuineIntel.dll"
start "" /D "%tmp%" NSudo.exe -U:T -P:E -M:S -ShowWindowMode:Hide cmd /c "del /f /q %WinDir%\System32\mcupdate_AuthenticAMD.dll"
echo Disable Spectre And Meltdown

::https://docs.microsoft.com/en-us/windows-hardware/drivers/display/gdi-hardware-acceleration
for /f %%a in ('Reg query "HKLM\System\CurrentControlSet\Control\Class" /v "VgaCompatible" /s 2^>nul ^| findstr "HKEY"') do Call :CurrentControlSet "%%a" "KMD_EnableGDIAcceleration" "1"
::Enable Hardware Accelerated Scheduling
call :ControlSet "Control\GraphicsDrivers" "HwSchMode" "2"
echo Enable Hardware Accelerated Scheduling

::Enable MSI Mode
for /f %%a in ('wmic path Win32_VideoController get PNPDeviceID ^| find "PCI\VEN_"') do call :ControlSet "Enum\%%a\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" "MSISupported" "1"
echo Enable MSI Mode on GPU
for /f %%a in ('wmic path win32_NetworkAdapter get PNPDeviceID ^| find "PCI\VEN_"') do call :ControlSet "Enum\%%a\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" "MSISupported" "1"
echo Enable MSI Mode on Net
for /f %%a in ('wmic path Win32_USBController get PNPDeviceID ^| find "PCI\VEN_"') do call :ControlSet "Enum\%%a\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" "MSISupported" "1"
echo Enable MSI Mode on USB

rem Turn off Inventory Collector
Reg add "HKLM\Software\Policies\Microsoft\Windows\AppCompat" /v "DisableInventory" /t REG_DWORD /d "1" /f >nul
rem Turn off Windows Error Reporting
Reg add "HKLM\Software\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d "1" /f >nul
rem Disable Application Telemetry
Reg add "HKLM\Software\Policies\Microsoft\Windows\AppCompat" /v "AITEnable" /t REG_DWORD /d "0" /f >nul
rem Disable the Customer Experience Improvement program (Below is 0 to disable)
Reg add "HKLM\Software\Policies\Microsoft\Internet Explorer\SQM" /v "DisableCustomerImprovementProgram" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\Software\Policies\Microsoft\SQMClient\Windows" /v "CEIPEnable" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\Software\Policies\Microsoft\AppV\CEIP" /v "CEIPEnable" /t REG_DWORD /d "0" /f >nul
Reg add "HKLM\Software\Policies\Microsoft\Messenger\Client" /v "CEIP" /t REG_DWORD /d "2" /f >nul
rem Disable Telemetry (Below is 1 to disable)
Reg add "HKLM\Software\Policies\Microsoft\MSDeploy\3" /v "EnableTelemetry" /t REG_DWORD /d "1" /f >nul
Call :ControlSet "Services\DiagTrack" "Start" "4"
Reg add "HKLM\Software\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d "0" /f >nul
rem Disable Text/Ink/Handwriting Telemetry
reg add "HKCU\Software\Microsoft\Input\TIPC" /v Enabled /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\Software\Policies\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\Software\Policies\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\Software\Policies\Microsoft\Windows\TabletPC" /v "PreventHandwritingDataSharing" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\Software\Policies\Microsoft\Windows\HandwritingErrorReports" /v "PreventHandwritingErrorReports" /t REG_DWORD /d "1" /f >nul
Reg add "HKCU\Software\Microsoft\Personalization\Settings" /v AcceptedPrivacyPolicy /t REG_DWORD /d 0 /f >nul
rem Disable Advertising ID
Reg add "HKLM\Software\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d "1" /f >nul
Reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d "0" /f >nul
echo Disable Telemetry

::Disable Biometrics
Reg add "HKLM\Software\Policies\Microsoft\Biometrics" /v "Enabled" /t REG_DWORD /d "0" /f >nul
echo Disable Biometrics

::Background Apps
Reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d "1" /f >nul
Reg add "HKLM\Software\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d "2" /f >nul
Reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v "BackgroundAppGlobalToggle" /t REG_DWORD /d "0" /f >nul
echo Disable Background Apps

::Disable Hibernation
call :ControlSet "Control\Power" "HibernateEnabled" "0"
powercfg /h off >nul
echo Disable Hibernation

::Raise the limit of paged pool memory
fsutil behavior set memoryusage 2 >nul
echo Raise the limit of paged pool memory

::https://www.serverbrain.org/solutions-2003/the-mft-zone-can-be-optimized.html
fsutil behavior set mftzone 2 >nul
echo Optimize the Mft Zone

::Enable Trim
fsutil behavior set disabledeletenotify 0 >nul
echo Enable Trim

::Disable Page File Encryption
fsutil behavior set encryptpagingfile 0 >nul
echo Disable Page File Encryption

::https://ttcshelbyville.wordpress.com/2018/12/02/should-you-disable-8dot3-for-performance-and-security/
fsutil behavior set disable8dot3 1 >nul
call :ControlSet "Control\FileSystem" "NtfsDisable8dot3NameCreation" "1"
echo Disable 8dot3

::Disable NTFS Compression
fsutil behavior set disablecompression 1 >nul
echo Disable NTFS Compression

wmic logicaldisk where "DriveType='3' and DeviceID='%systemdrive%'" get DeviceID 2>&1 | find "%systemdrive%" >nul && set "storageType=SSD" || set "storageType=HDD"
::Disable Last Access information on directories, performance/privacy
::https://www.tenforums.com/tutorials/139015-enable-disable-ntfs-last-access-time-stamp-updates-windows-10-a.html
if "%storageType%" equ "SSD" (fsutil behavior set disableLastAccess 0
call :ControlSet "Control\FileSystem" "NtfsDisableLastAccessUpdate" "2147483648") >nul
if "%storageType%" equ "HDD" (fsutil behavior set disableLastAccess 1
call :ControlSet "Control\FileSystem" "NtfsDisableLastAccessUpdate" "2147483649") >nul

::Opt out of nvidia telemetry
sc stop NvTelemetyContainer >nul
sc config NvTelemetyContainer start=disabled >nul
rundll32 "C:\Program Files\NVIDIA Corporation\Installer2\InstallerCore\NVI2.DLL",UninstallPackage NvTelemetryContainer
Reg add "HKLM\Software\NVIDIA Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\Software\NVIDIA Corporation\Global\FTS" /v "EnableRID44231" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\Software\NVIDIA Corporation\Global\FTS" /v "EnableRID64640" /t REG_DWORD /d 0 /f >nul
Reg add "HKLM\Software\NVIDIA Corporation\Global\FTS" /v "EnableRID66610" /t REG_DWORD /d 0 /f >nul
Reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "NvBackend" /f >nul 2>&1
schtasks /change /disable /tn "NvTmRep_CrashReport1_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}" >nul
schtasks /change /disable /tn "NvTmRep_CrashReport2_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}" >nul
schtasks /change /disable /tn "NvTmRep_CrashReport3_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}" >nul
schtasks /change /disable /tn "NvTmRep_CrashReport4_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}" >nul
echo Disable Nvidia Telemetry

::Fix CPU Stock Speed
call :ControlSet "Services\IntelPPM" "Start" "3"
call :ControlSet "Services\AmdPPM" "Start" "3"
echo Fix CPU Stock Speed

::Disable GpuEnergyDrv
call :ControlSet "Services\GpuEnergyDrv" "Start" "4"
echo Disable GpuEnergyDrv

::Disable HPET
bcdedit /set disabledynamictick yes >nul
bcdedit /deletevalue useplatformclock >nul 2>nul
for /f "tokens=2 delims==" %%G in ('wmic OS get buildnumber /value') do for /F "tokens=*" %%x in ("%%G") do (set "VAR=%%~x")
if !VAR! geq 19042 bcdedit /deletevalue useplatformtick >nul 2>nul
if !VAR! lss 19042 bcdedit /set useplatformtick yes >nul
echo Disable HPET

::Disable NetBios
call :ControlSet "Services\NetBT\Parameters\Interfaces" "NetbiosOptions" "2"
sc config lmhosts start=disabled >nul 2>&1
sc stop lmhosts >nul 2>&1
rem NetBios is disabled. If it manages to become enabled, protect against NBT-NS poisoning attacks
call :ControlSet "Services\NetBT\Parameters" "NodeType" "2"
echo Disable NetBios

::Power Plan
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb >nul 2>&1
powercfg /setactive bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb >nul
powercfg /delete eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee >nul 2>&1
powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee >nul 2>&1
powercfg /setactive eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee >nul
powercfg /delete bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb >nul
::Disable Frequency Scaling
powercfg -setacvalueindex scheme_current sub_processor PROCTHROTTLEMIN 100 >nul
::Throttle States: OFF
powercfg -setacvalueindex scheme_current sub_processor THROTTLING 0 >nul
::Device Idle Policy: Performance
powercfg -setacvalueindex scheme_current sub_none DEVICEIDLE 0 >nul
::Require a password on wakeup: OFF
powercfg -setacvalueindex scheme_current sub_none CONSOLELOCK 0 >nul
::USB 3 Link Power Management: OFF 
powercfg -setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0 >nul
::USB selective suspend setting: OFF
powercfg -setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul
::Link State Power Management: OFF
powercfg -setacvalueindex scheme_current SUB_PCIEXPRESS ASPM 0 >nul
::AHCI Link Power Management - HIPM/DIPM: OFF
powercfg -setacvalueindex scheme_current SUB_DISK 0b2d69d7-a2a1-449c-9680-f91c70521c60 0 >nul
::NVMe Power State Transition Latency Tolerance
powercfg -setacvalueindex scheme_current SUB_DISK dbc9e238-6de9-49e3-92cd-8c2b4946b472 1 >nul
powercfg -setacvalueindex scheme_current SUB_DISK fc95af4d-40e7-4b6d-835a-56d131dbc80e 1 >nul
::Interrupt Steering
echo %PROCESSOR_IDENTIFIER% | find /I "Intel" >nul && powercfg -setacvalueindex scheme_current SUB_INTSTEER MODE 6 >nul
::Enable Hardware P-states
powercfg -setacvalueindex scheme_current sub_processor PERFAUTONOMOUS 1 >nul
powercfg -setacvalueindex scheme_current sub_processor PERFAUTONOMOUSWINDOW 20000 >nul
powercfg -setacvalueindex scheme_current sub_processor PERFCHECK 20 >nul
::Dont restrict core boost
powercfg -setacvalueindex scheme_current sub_processor PERFEPP 0 >nul
::Enable Turbo Boost
powercfg -setacvalueindex scheme_current sub_processor PERFBOOSTMODE 1 >nul
powercfg -setacvalueindex scheme_current sub_processor PERFBOOSTPOL 100 >nul
::Disable Sleep States
powercfg -setacvalueindex scheme_current SUB_SLEEP AWAYMODE 0 >nul
powercfg -setacvalueindex scheme_current SUB_SLEEP ALLOWSTANDBY 0 >nul
powercfg -setacvalueindex scheme_current SUB_SLEEP HYBRIDSLEEP 0 >nul
::Disable Core Parking
echo %PROCESSOR_IDENTIFIER% | find /I "Intel" >nul && (
powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100
) || (
powercfg -setacvalueindex scheme_current SUB_INTSTEER UNPARKTIME 1
powercfg -setacvalueindex scheme_current SUB_INTSTEER PERPROCLOAD 10000
)
::Disable Frequency Scaling
powercfg -setacvalueindex scheme_current sub_processor PROCTHROTTLEMIN 100 >nul
::Configure C-States
powercfg -setacvalueindex scheme_current sub_processor IDLEPROMOTE 100 >nul
powercfg -setacvalueindex scheme_current sub_processor IDLEDEMOTE 100 >nul
powercfg -setacvalueindex scheme_current sub_processor IDLECHECK 20000 >nul
::Don't Higher P-States on Lower C-States And Viseversa
powercfg -setacvalueindex scheme_current sub_processor IDLESCALING 0 >nul
::Disable Idle
powercfg -setacvalueindex scheme_current sub_processor IDLEDISABLE 1 >nul
::Apply Changes
powercfg -setactive scheme_current >nul
powercfg -changename scheme_current "EchoX Ultimate Performance" "For EchoX Lite Optimizer %Version% (dsc.gg/EchoX) By UnLovedCookie" >nul
echo EchoX Power Plan

::Grab iGPU Registry Key
for /f %%i in ('Reg query "HKLM\System\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /t REG_SZ /s /e /f "Intel" ^| findstr "HKEY"') do (
::Disable iGPU CStates
Call :CurrentControlSet "%%i" "AllowDeepCStates" "0"
echo Disable iGPU CStates
::Intel iGPU Settings
Call :CurrentControlSet "%%i" "Disable_OverlayDSQualityEnhancement" "1"
Call :CurrentControlSet "%%i" "IncreaseFixedSegment" "1"
Call :CurrentControlSet "%%i" "AdaptiveVsyncEnable" "0"
Call :CurrentControlSet "%%i" "DisablePFonDP" "1"
Call :CurrentControlSet "%%i" "EnableCompensationForDVI" "1"
Call :CurrentControlSet "%%i" "NoFastLinkTrainingForeDP" "0"
Call :CurrentControlSet "%%i" "ACPowerPolicyVersion" "16898"
Call :CurrentControlSet "%%i" "DCPowerPolicyVersion" "16642"
echo Intel iGPU Settings
) >nul

::Grab Nvidia Graphics Card Registry Key
for /f %%a in ('Reg query "HKLM\System\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /t REG_SZ /s /e /f "NVIDIA" ^| findstr "HKEY"') do (
::Nvidia PState 0
Call :CurrentControlSet "%%a" "DisableDynamicPState" "1"
echo Disable Nvidia PStates
::Enable KBoost
Call :CurrentControlSet "%%a" "PowerMizerEnable" "1"
Call :CurrentControlSet "%%a" "PowerMizerLevel" "1"
Call :CurrentControlSet "%%a" "PowerMizerLevelAC" "1"
Call :CurrentControlSet "%%a" "PerfLevelSrc" "8738"
echo Enable KBoost
)

::NVCP
for /f "tokens=1" %%a in ('nvidia-smi --query-gpu^=driver_version --format^=csv 2^>nul') do set NvidiaDriverVersion=%%a
if "%NvidiaDriverVersion%" equ "528.24" (
if not exist "%tmp%\nvidiaProfileInspector\nvidiaProfileInspector.exe" (
curl -g -k -L -# -o "%tmp%\nvidiaProfileInspector.zip" "https://github.com/Orbmu2k/nvidiaProfileInspector/releases/latest/download/nvidiaProfileInspector.zip" >nul 2>nul
powershell -NoProfile Expand-Archive '%tmp%\nvidiaProfileInspector.zip' -DestinationPath '%tmp%\nvidiaProfileInspector\' >nul 2>nul
del /F /Q "%tmp%\nvidiaProfileInspector.zip"
)

del /F /Q "%tmp%\nvidiaProfileInspector\EchoProfile.nip"
::Enable Ultra Low Latency
call :NVCP "390467" "2"
call :NVCP "277041152" "1"
::Prefer Maximum Performance
call :NVCP "274197361" "1"
::Enable Anisotropic Optimizations
call :NVCP "8703344" "1"
call :NVCP "15151633" "1"
::Set Texture Filtering to High Performance
call :NVCP "13510289" "20"
call :NVCP "13510290" "1"
::Disable Cuda P2 State
call :NVCP "1343646814" "0"
::Enable All Thread Optimizations
call :NVCP "539870258" "31"
call :NVCP "544902290" "31"
call :NVCP "End"
start /D "%tmp%\nvidiaProfileInspector\" nvidiaProfileInspector.exe EchoProfile.nip
echo NVCP Settings
)


echo msgbox "Done^! Restart your computer to fully apply^." >"%tmp%\tmp.vbs"
wscript "%tmp%\tmp.vbs"
exit /b

:ControlSet
Reg add "HKLM\System\CurrentControlSet\%~1" /v "%~2" /t REG_DWORD /d "%~3" /f >nul
Reg add "HKLM\System\ControlSet001\%~1" /v "%~2" /t REG_DWORD /d "%~3" /f >nul
Reg add "HKLM\System\ControlSet002\%~1" /v "%~2" /t REG_DWORD /d "%~3" /f >nul
goto:EOF

:CurrentControlSet
set ControlSet=%1
Reg add !ControlSet! /v "%~2" /t REG_DWORD /d "%~3" /f >nul
Reg add !ControlSet:CurrentControlSet=ControlSet001! /v "%~2" /t REG_DWORD /d "%~3" /f >nul
Reg add !ControlSet:CurrentControlSet=ControlSet002! /v "%~2" /t REG_DWORD /d "%~3" /f >nul
goto:EOF

:NVCP
if not exist "%tmp%\nvidiaProfileInspector\EchoProfile.nip" (
echo ^<?xml version="1.0" encoding="utf-16"?^> > "%tmp%\nvidiaProfileInspector\EchoProfile.nip"
for %%a in (
"<ArrayOfProfile>"
"  <Profile>"
"    <ProfileName>Base Profile</ProfileName>"
"    <Executeables />"
"    <Settings>"
) do (echo %%~a) >> "%tmp%\nvidiaProfileInspector\EchoProfile.nip"
)

if "%~1" equ "End" (
for %%a in (
"    </Settings>"
"  </Profile>"
"</ArrayOfProfile>"
) do (echo %%~a) >> "%tmp%\nvidiaProfileInspector\EchoProfile.nip"
goto:EOF
)

for %%a in (
"      <ProfileSetting>"
"        <SettingID>%~1</SettingID>"
"        <SettingValue>%~2</SettingValue>"
"        <ValueType>Dword</ValueType>"
"      </ProfileSetting>"
) do (echo %%~a) >> "%tmp%\nvidiaProfileInspector\EchoProfile.nip"
goto:EOF