@echo off

::-------------------- Options --------------------
set dontInstallCurl=1
set verifySSL=1
set installJavaIfMissing=0

::-------------------- Variables --------------------
set debug=0
set title=Java Update Tool for JRE 8 x86 v1.0
if '%verifySSL%'=='0' (
  set curlExtraOptions=-k
) else (
  set curlExtraOptions=
)

::-----UAC Prompt----------------------------------
NET SESSION >nul 2>&1 && goto noUAC
title %title%
set n=%0 %*
set n=%n:"=" ^& Chr(34) ^& "%
echo Set objShell = CreateObject("Shell.Application")>"%tmp%\cmdUAC.vbs"
echo objShell.ShellExecute "cmd.exe", "/c start " ^& Chr(34) ^& "%title%" ^& Chr(34) ^& " /d " ^& Chr(34) ^& "%CD%" ^& Chr(34) ^& " cmd /c %n%", "", "runas", ^1>>"%tmp%\cmdUAC.vbs"
echo Not Admin, Attempting to elevate...
cscript "%tmp%\cmdUAC.vbs" //Nologo
del "%tmp%\cmdUAC.vbs"
exit /b
:noUAC

::-------------------- Initialize --------------------
setlocal enableextensions enabledelayedexpansion
color 17
title %title%
echo.
echo Started on %date% %time%

if '%debug%'=='1' goto quickstart

::-------------------- Messages --------------------
echo.
echo This software is brought to you by VCD
echo ^<https://vicidi.wordpress.com/^>
echo.
echo based on the original work from Grintor.
echo ^<Grintor at Gmail dot Com^>
echo.
echo This program is free software.
echo This program IS PROVIDED WITHOUT WARRANTY, EITHER EXPRESSED OR IMPLIED.
echo This program is copyrighted under the terms of GPLv3:
echo see ^<https://www.gnu.org/licenses/gpl-3.0-standalone.html^>.
echo.
FOR /L %%n IN (1,1,10) DO ping -n 2 127.0.0.1 > nul & <nul set /p =.
cls
echo.
echo If you find the program useful, please consider sending some Bitcoin to
echo the original author Grintor:
echo 12iNFT3n6yXz95mYttMcXWjm8UaEHVSjjr
echo.
FOR /L %%n IN (1,1,10) DO ping -n 2 127.0.0.1 > nul & <nul set /p =.
cls

:quickstart
::-------------------- Check cURL --------------------
echo.
echo Check avaibility of cURL...
curl -V >nul 2>&1 || goto installcurl
goto curlready
:installcurl
if '%dontInstallCurl%'=='1' goto nocurl
ping -n 1 google.com > nul || goto error
echo Installing cURL... && start /wait msiexec /i https://s3.amazonaws.com/grintor-public/curl.msi /q


:curlready
::----------- Find the latest java version----------------------------------
echo.
echo Searching for latest version of Java...
ping -n 1 google.com > nul || goto error

FOR /F "tokens=2 delims=<	> " %%n IN ('curl.exe -f -s -L %curlExtraOptions% http://javadl-esd.sun.com/update/1.8.0/map-m-1.8.0.xml ^| find /i "https:"') DO set URL1=%%n
if '%%n'=='' goto downloaderror
FOR /F "tokens=2 delims=<	> " %%n IN ('curl.exe -f -s -L %curlExtraOptions% %URL1% ^| find /i "<version>"') DO set RemoteJavaVersionFull=%%n
FOR /F "tokens=1 delims=-" %%n IN ("%RemoteJavaVersionFull%") DO set RemoteJavaVersion=%%n
if '%RemoteJavaVersion%'=='' goto downloaderror
if not '%RemoteJavaVersion:~0,3%'=='1.8' goto downloaderror
echo The latest version of Java is %RemoteJavaVersion%.




::----------- Find the local Java version-----------------------------------
set LocalJavaVersion=None
if defined ProgramFiles(x86) (
  set regPath=HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
) else (
  set regPath=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
)
FOR /F "tokens=1-15" %%n IN ('reg query %regPath% /s 2^> nul') DO (

  if '%%n'=='InstallSource' (
    set p=%%p%%q%%r%%s%%t%%u%%v%%w%%x%%y%%z
    set p=!p: =\!
    set p=!p:\= !
    for %%n in (!p!) do set c=%%n
  )

  if '%%n'=='DisplayName' (
    set p=%%p
    if "!p:~0,4!"=="Java" if not "%%q"=="Auto" if not '!LocalJavaVersion!'=='None' (set LocalJavaVersion=Multi) ELSE (set LocalJavaVersion=!c:~3!)
    if "!p:~0,4!"=="J2SE" if not '!LocalJavaVersion!'=='None' (set LocalJavaVersion=Multi) ELSE (set LocalJavaVersion=!c:~3!)
  )
)

if '%LocalJavaVersion%'=='None' (
  echo There is no local version of Java.
  if '%installJavaIfMissing%'=='1' (goto download) else (goto noerror)
)
if '%LocalJavaVersion%'=='Multi' echo There are multiple local versions of Java installed. & goto download
echo The local version of Java is %LocalJavaVersion%.



::----------- If they match, skip to the end---------------------------------
if '%RemoteJavaVersion%'=='%LocalJavaVersion%' (goto finished) ELSE (echo The local version of Java is out of date.)



::-------------------- Download the latest Java --------------------
:download
echo Downloading latest version of Java...
set url2=http://javadl.sun.com/webapps/download/GetFile/%RemoteJavaVersionFull%/windows-i586/xpiinstall.exe
curl.exe -f -s -L %curlExtraOptions% -o %tmp%\java_inst.exe %url2%
if ERRORLEVEL 1 goto downloaderror
if '%LocalJavaVersion%'=='None' goto install



::----------- Uninstall all currently installed java versions----------------
:uninstall
if '%LocalJavaVersion%'=='Multi' (echo Uninstalling all local versions of Java...) ELSE (echo Uninstalling the local version of Java...)
FOR /F "tokens=1-4" %%n IN ('reg query %regPath% /s 2^> nul') DO (

  if '%%n'=='UninstallString' (
    set c=%%q
    set c=!c:/I=/X!
  )

  if '%%n'=='DisplayName' (
    set d=%%p
    if "!d:~0,4!"=="Java" if not "%%q"=="Auto" msiexec.exe !c! /qn /norestart & ping -n 11 127.0.0.1 > nul
    if "!d:~0,4!"=="J2SE" msiexec.exe !c! /qn /norestart & ping -n 11 127.0.0.1 > nul
  )
)



::-------------------- Install --------------------
:install
echo Installing latest version of Java...
start /wait %tmp%\java_inst.exe INSTALL_SILENT=1 REBOOT=0
ping 127.0.0.1 > nul
del %tmp%\java_inst.exe



::----------- Up to date ----------------------------------------------------
:finished
echo Your Java is up to date.
echo.


::----------- There was an error---------------------------------------------
goto noerror
:error
echo.
echo There was a network error. Please check your internet connection.
goto noerror
:nocurl
echo.
echo cURL cannot be found
echo Please configure it manually, or change
echo 'set dontInstallCurl=1' to 'set dontInstallCurl=0'
echo in this batch file to allow automatic installation
goto noerror
:downloaderror
echo.
echo There was a network error. Please try again later.
goto noerror
:noerror

endlocal
FOR /L %%n IN (1,1,10) DO ping -n 2 127.0.0.1 > nul & <nul set /p =.
