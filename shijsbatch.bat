
title shijs batch
wchcp 65001
@echo off
setlocal enabledelayedexpansion


color 0c

if "%1"==":a" goto :a

:menu
mode 87,26
cls                                                                  
echo    ####    #    #   #        #    ####      #####     ##    #####   ####   #    #
echo   #        #    #   #        #   #          #    #   #  #     #    #    #  #    #
echo    ####    ######   #        #    ####      #####   #    #    #    #       ######
echo        #   #    #   #        #        #     #    #  ######    #    #       #    #
echo   #    #   #    #   #   #    #   #    #     #    #  #    #    #    #    #  #    #
echo    ####    #    #   #    ####     ####      #####   #    #    #     ####   #    #
echo.                                                                                    
echo you may press B at any point to come back to this menu
echo.
echo -1-shortcuts
echo -2-fetch
echo -3-terminal
echo -4-task manager
echo -5-miscellaneous            
set /p choice=

if /i "%choice%"=="1" call :shortcuts_menu
if /i "%choice%"=="2" call :fetch
if /i "%choice%"=="3" call :terminal
if /i "%choice%"=="4" call :taskmanager
if /i "%choice%"=="5" call :extra
goto menu


:shortcuts_menu
cls

:: initialize shortcuts.txt if it doesn't exist
if not exist shortcuts.txt (
    cls
    echo no shortcuts found. creating shortcuts.txt...
    echo. > shortcuts.txt
    attrib +h shortcuts.txt
    echo shortcuts.txt has been created and set to hidden.
    pause
)

:show_shortcuts
cls
echo shortcuts:
echo ---------------
setlocal enabledelayedexpansion

for /f "tokens=1 delims=;" %%a in (shortcuts.txt) do (
    echo %%a
)

echo ---------------
echo type 'create' to add a new shortcut, 'delete [name]' to remove one
echo type the name of the shortcut you wanna open
echo type 'exit' to go back to the main menu.
set /p shortcut_choice="choose an option: "

if /i "%shortcut_choice%"=="create" (
    call :create_shortcut
    goto show_shortcuts
) else if "%shortcut_choice:~0,7%"=="delete " (
    call :delete_shortcut "%shortcut_choice:~7%"
    goto show_shortcuts
) else if /i "%shortcut_choice%"=="exit" (
    goto menu
) else (
    call :open_shortcut "%shortcut_choice%"
    goto show_shortcuts
)

choice /c B /n
if errorlevel 1 goto menu

:create_shortcut
cls
set /p shortcut_name="enter shortcut name (type 'exit' to go back): "
if /i "%shortcut_name%"=="exit" goto shortcuts_menu


set /p shortcut_path="enter the full path for the shortcut (type 'exit' to go back): "
if /i "%shortcut_path%"=="exit" goto shortcuts_menu

:: check if the shortcut already exists
findstr /x /c:"%shortcut_name%;%shortcut_path%" shortcuts.txt >nul
if %errorlevel%==0 (
    echo a shortcut with that name already exists.
    pause
    goto shortcuts_menu
)


:: add shortcut to file
echo %shortcut_name%;%shortcut_path% >> shortcuts.txt
echo shortcut added successfully.

choice /c B /n
if errorlevel 1 goto menu

pause
goto shortcuts_menu

:delete_shortcut
cls
set "delete_name=%~1"
:: search and remove the shortcut
findstr /v /c:"%delete_name%;" shortcuts.txt > temp.txt
move /y temp.txt shortcuts.txt >nul
echo shortcut '%delete_name%' deleted.
pause
goto shortcuts_menu
 
choice /c B /n
if errorlevel 1 goto menu

:open_shortcut
cls
set "shortcut_name=%~1"

choice /c B /n
if errorlevel 1 goto menu

goto shortcuts_menu




:fetch
cls
set "currentuser=%username%"

:: operating system
for /f "tokens=2*" %%i in ('reg query "hklm\software\microsoft\windows nt\currentversion" /v productname ^| findstr /c:"productname"') do (
    set "os=%%j"
)
set "os=!os:microsoft =!"

echo operating system: !os!

:: disk usage
set "output="
for /f "tokens=1,2,3 delims=," %%a in ('powershell -noprofile -command "get-psdrive -psprovider filesystem | foreach-object { if ($_.used -gt 0) { $_.name + ',' + [math]::round($_.used/1gb, 0) + ',' + [math]::round(($_.used + $_.free)/1gb, 0) } }"') do (
    set "output=!output!%%a: %%b/%%cgb "
)
echo disk usage: !output!

:: processor information
for /f "tokens=*" %%i in ('wmic cpu get name ^| findstr /r /v "^$"') do (
    set "cpu=%%i"
)
echo processor: !cpu!

:: total ram
for /f "tokens=1" %%b in ('powershell -noprofile -command "get-wmiobject win32_computersystem | foreach-object { [math]::round($_.totalphysicalmemory / 1gb, 2) }"') do (
    set "ramoutput=%%b gb"
)
echo total ram: !ramoutput!

:: RAM usage (used and free)
for /f "tokens=2 delims==" %%a in ('wmic OS get freephysicalmemory /value') do set "freeram=%%a"
for /f "tokens=2 delims==" %%a in ('wmic OS get totalvisiblememorysize /value') do set "totalram=%%a"

if not defined totalram (
    echo Failed to retrieve total RAM.
    pause
    exit /b
)

if not defined freeram (
    echo Failed to retrieve free RAM.
    pause
    exit /b
)

set /a "usedram=%totalram% - %freeram%"
set /a "freerammb=%freeram% / 1024"
set /a "usedrammb=%usedram% / 1024"

echo used ram: %usedrammb% MB
echo free ram: %freerammb% MB

:: GPU Information using PowerShell
for /f "tokens=*" %%a in ('powershell -Command "Get-WmiObject Win32_VideoController | Select-Object -ExpandProperty Caption"') do (
    set "gpu=%%a"
)


:: system architecture
for /f "skip=1" %%i in ('wmic os get osarchitecture') do (
    set "arch=%%i"
    goto :break_arch
)
:break_arch
echo architecture: !arch!

:: motherboard model
for /f "tokens=*" %%i in ('wmic baseboard get product ^| findstr /r /v "^$"') do (
    set "motherboard=%%i"
)
echo motherboard: !motherboard!

:: pc model
for /f "tokens=*" %%i in ('wmic csproduct get name ^| findstr /r /v "^$"') do (
    set "pcmodel=%%i"
)
echo pc model: !pcmodel!

:: display resolution
for /f "tokens=1,2" %%a in ('wmic path win32_videocontroller get currenthorizontalresolution^,currentverticalresolution ^| findstr /r "^[0-9]"') do (
    set "width=%%a"
    set "height=%%b"
)
echo screen resolution: !width! x !height!

:: last boot time and uptime calculation
for /f "skip=1 tokens=1" %%a in ('wmic os get lastbootuptime') do (
    set lastboot=%%a
    goto :parselastboot
)

:: last boot time and uptime calculation
for /f "skip=1 tokens=1" %%a in ('wmic os get lastbootuptime') do (
    set lastboot=%%a
    goto :parselastboot
)

:parselastboot
set lastbootyear=!lastboot:~0,4!
set lastbootmonth=!lastboot:~4,2!
set lastbootday=!lastboot:~6,2!
set lastboothour=!lastboot:~8,2!
set lastbootminute=!lastboot:~10,2!

:: format boot time for display
set boottime=!lastbootyear!-!lastbootmonth!-!lastbootday! !lastboothour!:!lastbootminute!

:: calculate uptime
for /f "tokens=2 delims==" %%a in ('wmic os get localdatetime /value') do set currenttime=%%a
set currentyear=!currenttime:~0,4!
set currentmonth=!currenttime:~4,2!
set currentday=!currenttime:~6,2!
set currenthour=!currenttime:~8,2!
set currentminute=!currenttime:~10,2!

:: convert times to total minutes since a reference point (e.g., 0000-01-01)
set /a lastbootminutes=(1!lastbootyear:~2,2! * 525600) + (1!lastbootmonth! * 43800) + (1!lastbootday! * 1440) + (1!lastboothour! * 60) + 1!lastbootminute!
set /a currentminutes=(1!currentyear:~2,2! * 525600) + (1!currentmonth! * 43800) + (1!currentday! * 1440) + (1!currenthour! * 60) + 1!currentminute!

set /a uptime_minutes=currentminutes - lastbootminutes
set /a uptime_days=uptime_minutes / 1440
set /a uptime_hours=(uptime_minutes %% 1440) / 60
set /a uptime_remaining_minutes=uptime_minutes %% 60

:uptime_loop
cls
echo                            /\     /\ 
echo                           /  \   /  \ 
echo                          /    \_/    \ 
echo                         ^| _     _     \ 
echo                       .^'  _     _  '.. ^| 
echo                      /   (_)   (_)     \ 
echo                     ^|     _______      ^| 
echo                     ^|    ^|       ^|     ^| 
echo                     ^|    ^|       ^|   ; ^| 
echo                      \    \_____/     / 
echo                       '^.           .'^  
echo                         ^'\\____._///^'  

echo current user: %username%
echo operating system: !os!
echo disk usage: !output!
echo processor: !cpu!
echo GPU: !gpu!
echo total ram: !ramoutput!
echo used ram: %usedrammb% MB
echo free ram: %freerammb% MB
echo architecture: !arch!
echo motherboard: !pcmodel!

echo screen resolution: !width! x !height!
echo boot time: !boottime!
echo uptime: %uptime_days% days, %uptime_hours% hours, %uptime_remaining_minutes% minutes

:: wait for 60 seconds before refreshing the information
timeout /t 60 >nul
 
choice /c B /n
if errorlevel 1 goto menu

:: loop back to the uptime calculation
goto :uptime_loop

if /i "%choice%"=="B" call :menu



:matrix
color 0a
@echo off

cls

pause

:start

echo matrix

timeout /t 1 >nul 

echo .              
timeout /t 1 >nul 

echo ..
timeout /t 1 >nul

echo ...
timeout /t 1 >nul

cls
goto numbers


:numbers
echo %random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%



goto numbers


:ascii
cls
mode 152,130

echo                        WWMMMMGGGGGGGGGGGGGGGGGMMMMMMMMGGMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW
echo                       WWMMMMGGGGGGGGGGGGGGGGGGMMMMMMMMGGMMMMMMMMMMMMWWWWRWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW
echo                       WWMMMGGGGGGGGGGGGGGGGGGGMMMMMMMMMMMMMMMMMMMMGWWWWGMMRRMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW
echo                      WWMMMGGGGGGGGGGGGGGGGGGGGGMMMMMGMMMMMMMMMMMGWWW.WWGMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMGGGGMMMMMMMMMMMMMMMMMMMMMMMW
echo                     WWMMMMGGGGGGGGGGGGGGGGGGGGGGGMMGGGMMGGMMMGGGWW....WGMMMMMMMWWWWWMMMMMMMMMMMGGGGGGGGGGGGGGGGGGGGGGGGGMGMMWWWWMMMMMMMMMMMMMMMW
echo                     WWMMMMGGGGGGGGGGGGGGGGGGGGGGGGMGGMMMMMMGGGWW......WWGMMMMMGGGGWMMRWWMMMMMMMMMMMGGGGGGGGMMMMGGGGGGGGGGMWWWWWWMMGMMMMMMMMMMMMW
echo                    WWMMMMGGGGGGGGGGGGGGGGGGGGGGGGMGGGGGGGGGGWWW........WWMMMMMMGGGGGGMWWMMMWMGGGGGGGGGGGGGGGGGGGGGGGGGGGGMWWMMGGGGGGGGGGMMMMMMMWW
echo                   WWMMMMMGGGWWWWGGGGGGGGGGGGGGGGGGGGGGGGGGGWW..WWWW....WWGMMMMMGGGGGGGGGGMMMMMMMMGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGMMMGMMMMMWWW
echo                  WWMMMMMGGWWWWWGGGGGGGGGGGGGGGGGGGGGGGGGWW.WWW...WW....WWGMMMMGGGGGGGGGGGGGGMMMWWWWGMGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGMGMMMWWWW
echo                  WWMMMMMMMW.WWWWGGGGGGGGGGGGGGGGGGGGGGGGWW.WW......WW....WWGMMMMGGGGGGGGGGGGGGGGMMWRMWWMWGGGGGGGGGGGGGGWGGGGGGGGGGGGGGGGMMMMWWWW
echo                 WMMMMMMMW...WWWGGGGGGGGGGGGGGGGGGGGGGWWWWWWWWW....WWW....WWMMMMGGGGGGGGGGGGGGGGGGGGGGWWMWWWMMMMGGGGGGGWWGGGGGGGGGGGGGMMMWWWWWMWW
echo                 WWMMMMMMMW..WWWWGGGGGGGGGGGGGGGGGGGGGWWWW.....WWWWWWWWW....WWMMMMGGGGWWGGGGGGGGGGGGGGGGGGGGGWMWMMMMMMMMWWGGMMMWWWWWWWWWWWWWWMMMW
echo                WWMMMMMMMMW.WW.WWGGGGGGGGGGGGGGGGGGGWWWW............WWWWW....WWMMMMGGGWWWWGGGGGGGMWWGGGGGGGGGGGGGGGGGGGGGWWGWWGGWWWWWWWWWMGMMMMGW
echo               WWMMMMMMMMMW.W..WWGGGGGGGGGGGGGGGGGGWWWW................WWWW...WWMMMMMMMWWWWGGGGGGWWWGGGGGGGGGGGGGGGGGGGGGGWGGGGGGGGGGGGGGGGGGMMGW
echo               WWMGGGGGGMMW.WW..WGGGGGGGGGGGGGGGGGWWW.............WWWW...WWWWW.WWMMMMMMMW.WWWGGGGGGGGGGGGGGGGGGGGGGGGGGGGGWWGGGGGGGGGGGGGGGGGGGGW
echo              WWMGGGGGGGGGW.WW..WGGGGGGGGGGGGGGGGWWWWWWWWWWW........WWWW..WW.WWWWWMMMMMMMW..WWWWGGGGGGGGGGGGGGGGGGGGGGGGGGGWGGGGGGGGGGGGGGGGGGGGMW
echo             WWMGGGGGGGGGGGWW...WWGGGGGGGGGGGGGGGGWWWWWWWWWWWWWWW.....WWWW.WWW.W.WWWMMMMMMW...WWWWGGGGGGGGGGGGGGGGGGGGGGGGGWWGGGGGGGGGGGGGGGGGGGGW
echo            WWMGGGGGGGGGGGGWWW..WWGGGGGGGGGGGGGGGGWWWGGGMGGMMMMMWWWWWW.WWW...WWW...WWMMMMMMW....WWWWGGGGGGGGGGGGGGGGGGGGGGGWWGGGGGGGGGGGGGGGGGGGMW
echo           WWMGGGGGGGGGGGGGW.WW.WWGGGGGGGGGGGGGGGWWWWGGGWGGWWWGWWWWWWWWWWW.....WW...WWWMMMMMW.....WWWWWGGGGGGGGGGGGGGGGGGGGWGGGGGGGGGGGGGGGGGGGGGW
echo          WWGGGGGGGGGGGGGGGW.WWWWGGGGGGGGGGGGGGGWWWWWWWGGWWW.WWWW...WWWW.......WWWWW.WWWMMMMW...WW..WWWWGGGGGGGGGGGGGGGGGWWWWWWWWWWGGGGGGGGGGGGGW
echo          WWMGGGGGGGGGGGGGGGWW...WWGGGGGGGGGGGGGMWWWWWWWWWWWWWWWW.................WWW...WWMMMMWW........WWWWGGGGGGGGGGGGGGWWWWWWWWWGGGGGGGGGGGGGGWW
echo         WWGGGGGGGGGGGGGGGGGGGWW.WWGGGGGGGGGGGGGMW.WWWWWWWWWWWWW...................WWWW..WWWMMMWW....WWWWW.WWWWGMGGGGGGGGGWGGGGGGGGGGGGGGGGGGGGGGWW
echo        WWGGGGGGGGGGGGGGGGGGGGGWWWWWGGGGGGGGGGGMMW...WWWWWWWWW....................WWWWWWW.WWWWWMWW..WWWWWWWWWWWWWGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGWW
echo       WWGGGGGGGGGGGGGGGGGGGGGGGGWWWGGGGGGWWWGGMMW.......WWWWWWW..................WWWW..WWWWWWWWWMWWWWWWWWWWWWWWWWWWWGGGGGGGGGGGGGGGGGGGGGGGGGGGGGWW
echo      WWWWGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGWW.WWGMMW...............................WW.....WWWWWWW.WWGWGGGGGWWWWWWWWWWWWWWWWGGWGGGGGGGGGGGGGGGGGGGGGGWW
echo     WWWWWGGGGGGGGGGGGGGGGGGGGGGGGGWGGGGWW..WWGMW.............................WWW.......WW..WWWWWGWWWWWGWWW....WWWWW..WWGGGGGGGGGGGGGGGGGGGGGGGGGWW
echo    WWGWGGGGGGGGGGGGGGGGGGGGGGGGGGGWWGGW......WMWWW.......................WWWWW........WW.....WWWWWWWWWWWW.....WWWWWWWWWGGGGGGGGGGGGGGGGGGGGGGGGGWW
echo    WWGGGGGGGWGGGGGGGGGGGGGGGGGGGGGGWWWWW..........WWWWW................WWWWWW.........WW.....WWWWWWWWWW......WWW...WWWGGWGGGGGGGGGGGGGGGGGGGGGGW
echo   WWGGGGGGGGGKIZUMONOGATARIGGGGGGGGWWWW..............WWWWWWW...WWWWWWWWW..............WW......WWWWWWW.......WWWWW.WWWGGGGGGGGGGGGGGGGGGGGGGGGGGW
echo   WWGGWGGGGGGGGGGGGGGGGGGGGGGGGGGGGGWWWW...................WWWWWW......................WW........WWWWWW......WW.WWWWWWGGGGWGGGGGGGGGGGGGGGGGGGGWW
echo   WWGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGWWWWW.........................................W....WWW......................WWWWWGGGGGGGGGGGGGGGGGGGGGGGGGGW
echo    WWGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGWTW.WW.......................................WW.....WWW....................WWWWWGGGGGGGGGGGGGGWGGGGGGGGGGGGW
echo    WWGWGGGGGGGGGGGGGGGGGGGGGGGGGGGGGWTWW.WW......................................WW.......WWW..................WWWWWGGGGGGGGGGGGGWGGGGGGGGGGGGGW
echo     WWWGGGGGGGGGGGGGGGGGGGGGGGGGGGGWO.WW.WW...................................WWW..........WWW...............WWWWWGWGGWGGGGGGGGGWGGGGGGGGGGGGGGW
echo      WWWGGGGGGGGGGGGGGGGGGGGGGGGGGGGWO..WW.WW................................................WWWWW..........WWWWWWGGGGWGGGGGGGWWGGGGGGGGGGGGGGW
echo       WWGGGGGGGGGGGGGGGGGGGGGGGGWWWWWW...WW.WW...............WWW................................WWWWWWWWWWWWWWWWWGGGGWGGGGGGGWWGGGGGGGGGGGGGGGW
echo       WWWGGGGGGGGGGGGGGGGGGGGWWWWRRRRW....WW.WW...............WWW...................................WWWWWWWWGGGGGGGGGGGGGWGGGWGGGGWGGGGGGGGGGGW
echo        WWWGGGGGGGGGGGGGGGGGWWMRRRRRRRW.....WWWWW................WWWW...................................WWWGGGGGGGGGGGGGGGWGWGGGGGGGGGGGGGGGGGWW
echo         WWWGGGGGGGGGGGGGGGWWMRRRRRRRRW.......WW.WW.................WWWWWW......WW....................WWWGGGGGGGGGGWGGGGGGWWGGGGGGGGWWGGGGGGGGW
echo          WWWGGGGGGGGGGWWWWWRRRRRRRRRRW........WW.WW.....................WWWWWWWW...................WWWGGGGGGGGGGGGGGGGGGGGGGGGGGGWGGWGGGGGGGWW
echo          WWWWGGGGGWWWW..WWRRRRRRRRRRRWT.........WWWWW...........................................WWWWWGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGWGGGGGGGW
echo            WWWGWWWW....WWRRRRRRRRRRRRWW..........WWWWW.......................................WWWWRRRWWWWGGGGGGGGGGGGGGGGGGGGGGGGGGGGGWGGGGGW
echo              WWW......WWRRRRRRRRRRRRWWW............WWWWW.................................WWWWWRRRRRRRRWWGGGGGGGGGGGGGGGGGGGGGGGGGGGGGWGGGGWW
echo         WWWWW.WW.....WWRRRRRRRRRRRRRWTW..............WWWWW.........................WWWWWWWRRRRRRRRRRWOWWWWWWGGGGGGGGGGGGGGGGGGGGGGGGGWGGGW
echo WWWWWWWWWW.W...W....WWWRRRRRRRRRRRRRRW.W................WWWWW.................WWWWWWWWWRRRRRRRRRRRRRAWWW...WWWWWGGGGGGGGGGGGGGGGGGGGGGWGGW
echo WW.............W...WWRRRRRRRRRRRRRRRWW.W...................WWWW.........WWWWWWW..WWWWRRRRRRRRRRRRRRATWW........WWWWWGGGGGGGGGGGGGGGGWGGWW
echo ...............WW.WWRRRRRRRRRRRRRRRRWT.W.....................WWWWWWWWWWWW......WWWWWRRRRRRRRRRRRRROTTW............WWWWWGGGGGGGGGGGGWGGWW
echo ................WWWRRRRRMMMRMMMRRRRWW..W....................................WWWWWWRRRRRRRRRRRRRWATTTW................WWWWWWGGGGGGGGGWW
echo ................WWWRRRMMMMMMMMMMMRMWT..W.................................WWWWWWWRRRRRRMRMMMRRRAOTTTWW....................WWWWWWWWWWWWWWW
echo ..............WWWRRRRMMMMMMMMMMMMMMWT.TW..............................WWWWTTWWRRRRRWWAARMMMWAOTTTTWW..................................WWWWWWWWWWWW
echo ..............WWWWWWWMMMMMMMMMMMMMMWT.WT............................WWW...TWWRRRRRAOOOAMMMRAOTTTTTW............................................WWW
pause > nul  REM 

choice /c B /n
if errorlevel 1 goto menu

goto main


:extra
mode 87,26
cls

echo -B- menu
echo -1- open cmd
echo -2- packages
echo -3- test internet connection
echo -4- colors
echo -5- refresh icon cache
echo -6- ascii hanekawa art
echo -7- matrix
echo -8- display all system info
echo -9- all DOS commands
set /p choice=


if /i "%choice%"=="B" call :menu
if /i "%choice%"=="1" call :cmd
if /i "%choice%"=="2" call :packages
if /i "%choice%"=="3" call :internet
if /i "%choice%"=="4" call :colors
if /i "%choice%"=="5" call :refresh_icon_cache
if /i "%choice%"=="6" call :ascii
if /i "%choice%"=="7" call :matrix
if /i "%choice%"=="8" call :systeminfo
if /i "%choice%"=="9" call :DOS
goto extra

:cmd
cls

start cmd /K "echo cmd succsesfully opened"

goto extra

:internet

:check_connection
mode 50,3
echo.
echo please wait... checking internet connection...
timeout /t 1 /nobreak >nul
ping www.google.com -n 1 -w 1000 >nul && set "internet=connected" || set "internet=not connected"

:: Get Local IP Address
for /f "tokens=14" %%I in ('ipconfig ^| findstr /i "IPv4"') do set LocalIP=%%I

:: Get Public IP Address
for /f "delims=" %%I in ('curl -s https://api.ipify.org') do set PublicIP=%%I

:: Display both IPs
echo your local IP address is: %LocalIP%
echo your public IP address is: %PublicIP%

pause
goto :extra

:refresh_icon_cache
cls
echo refreshing icon cache...
taskkill /im explorer.exe /f
del /a:h "%localappdata%\microsoft\windows\explorer\iconcache*" >nul 2>&1
start explorer.exe
echo icon cache refreshed.
pause
goto extra

:colors
cls

echo select a text color
echo -1- black
echo -2- red
echo -3- green
echo -4- yellow
echo -5- blue
echo -6- magenta
echo -7- cyan
echo -8- white
set /p fgChoice=


echo select a background color
echo -1- black
echo -2- red
echo -3- green
echo -4- yellow
echo -5- blue
echo -6- magenta
echo -7- cyan
echo -8- white
set /p bgChoice=


:: set the foreground and background colors based on user input
if "%fgChoice%"=="1" set fgColor=0
if "%fgChoice%"=="2" set fgColor=4
if "%fgChoice%"=="3" set fgColor=2
if "%fgChoice%"=="4" set fgColor=6
if "%fgChoice%"=="5" set fgColor=1
if "%fgChoice%"=="6" set fgColor=5
if "%fgChoice%"=="7" set fgColor=3
if "%fgChoice%"=="8" set fgColor=7

if "%bgChoice%"=="1" set bgColor=0
if "%bgChoice%"=="2" set bgColor=4
if "%bgChoice%"=="3" set bgColor=2
if "%bgChoice%"=="4" set bgColor=6
if "%bgChoice%"=="5" set bgColor=1
if "%bgChoice%"=="6" set bgColor=5
if "%bgChoice%"=="7" set bgColor=3
if "%bgChoice%"=="8" set bgColor=7

:: apply the colors using the 'color' command
color %bgColor%%fgColor%

:: display the selected colors
cls
echo you have selected text color %fgChoice% and background color %bgChoice%.


choice /c B /n
if errorlevel 1 goto extra

pause

:taskmanager
mode 87,26

:taskmenu
cls
echo          Windows 98 Task Manager
echo [B]menu
echo [1]processes
echo [2]kill process
echo [3]performance
set /p choice= 

if "%choice%"=="1" goto :processes
if "%choice%"=="3" goto :performance
if "%choice%"=="2" goto :killprocess
if "%choice%"=="b" goto :menu

goto :taskmenu

:taskmenu2
timeout /t 3 /nobreak >nul

echo [B]back
echo [K]kill process
set /p choice= 

if "%choice%"=="k" goto :killprocess
if "%choice%"=="b" goto :taskmenu

goto :taskmenu2

:processes
cls
echo                 processes
wmic process get description,processid | more
goto :taskmenu2

:performance
start cmd /k "call shijsbatch.bat :a"
goto :taskmenu

:a
color 0f
mode 51,5
cls


:: Get CPU Usage
for /f "tokens=2 delims==" %%a in ('wmic cpu get loadpercentage /value') do set cpu=%%a

:: Get RAM Usage
for /f "tokens=2 delims==" %%a in ('wmic OS get FreePhysicalMemory /value') do set freeram=%%a
for /f "tokens=2 delims==" %%a in ('wmic OS get TotalVisibleMemorySize /value') do set totalram=%%a
set /a usedram=%totalram% - %freeram%
set /a freerammb=%freeram% / 1024
set /a usedrammb=%usedram% / 1024
set /a totalrammb=%totalram% / 1024

:: Output the data
echo ==============================================
echo  CPU Usage: %cpu%%  
echo  RAM Usage: %usedrammb%MB / %totalrammb%MB  
echo ==============================================

:: wait 1 second before refreshing the data
ping -n 2 127.0.0.1 >nul

:: Automatically refresh performance data
goto :a

:killprocess
cls

echo               kill process by name
echo Enter the name of the process to kill (e.g., notepad.exe):
set /p processname=Process: 

:: Kill the process by name
taskkill /im "%processname%" /f >nul 2>&1

:: Check if the process was successfully terminated
if %errorlevel%==0 (
    echo Process "%processname%" has been killed.
) else (
    echo Failed to kill process "%processname%" or it may not exist.
)

echo ==============================================

choice /c B /n
if errorlevel 1 goto taskmenu

:packages
cls
echo -B-back
echo -1-install choco (package manager) [need to run batch as admin]
echo -2-install packages                [need to run batch as admin]
echo -3-usage      
echo -4-check packages                  [need to run batch as admin]
echo -5-uninstall choco                 [need to run batch as admin]
echo. 
echo packages are listed in  "usage"
set /p choice=


if /i "%choice%"=="B" call :extra
if /i "%choice%"=="1" call :choco
if /i "%choice%"=="2" call :installpgk
if /i "%choice%"=="3" call :usage
if /i "%choice%"=="4" call :installed
if /i "%choice%"=="5" call :uninstallchoco


goto packages

:choco
cls

echo Opening PowerShell to enable script execution and install Chocolatey...

powershell -NoExit -Command ^
"Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; ^
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')); ^
[System.Environment]::SetEnvironmentVariable('Path', $env:Path + ';C:\ProgramData\chocolatey\bin', [System.EnvironmentVariableTarget]::User); ^
echo Installation Complete. Please restart your command prompt."

echo press any key
pause 

:installpgk
cls
echo Opening PowerShell to install packages with Chocolatey...
echo This may take some time depending on your internet speed.

REM Run PowerShell script to install packages via Chocolatey directly
powershell -Command "
    choco install nano -y --confirm --accept-license --no-progress;
    choco install neofetch -y --confirm --accept-license --no-progress;
    choco install wget -y --confirm --accept-license --no-progress;
    choco install git -y --confirm --accept-license --no-progress;
    choco install htop -y --confirm --accept-license --no-progress;
    choco install p7zip -y --confirm --accept-license --no-progress;
    choco install kitty -y --confirm --accept-license --no-progress;
    choco install xterm -y --confirm --accept-license --no-progress;
    choco install mediainfo -y --confirm --accept-license --no-progress;
    choco install poppler -y --confirm --accept-license --no-progress;
    choco install transmission-cli -y --confirm --accept-license --no-progress;
    choco install cmatrix -y --confirm --accept-license --no-progress;
    choco install cowsay -y --confirm --accept-license --no-progress;
    choco install bmon -y --confirm --accept-license --no-progress;
    choco install screenfetch -y --confirm --accept-license --no-progress;
    choco install morse -y --confirm --accept-license --no-progress;
    choco install watch -y --confirm --accept-license --no-progress;
    choco install cal -y --confirm --accept-license --no-progress;
    choco install bb -y --confirm --accept-license --no-progress;
    choco install pipes.sh -y --confirm --accept-license --no-progress;
    choco install figlet -y --confirm --accept-license --no-progress;
    choco install lolcat -y --confirm --accept-license --no-progress;
    choco install toilet -y --confirm --accept-license --no-progress;
    choco install asciiquarium -y --confirm --accept-license --no-progress;
"

echo Installation process completed!
pause

:usage
cls
echo nano: terminal-based text editor. run: nano filename
echo neofetch: displays system information. run: neofetch
echo wget: downloads files from the web. run: wget [url]
echo git: version control tool. run: git [command]
echo htop: interactive process viewer. run: htop
echo p7zip: archive manager. run: 7z [command]
echo kitty: terminal emulator. run: kitty]
echo xterm: x11 terminal emulator. run: xterm
echo mediainfo: displays media file info. run: mediainfo [file]
echo poppler: pdf rendering library. run: pdftoppm [file]
echo transmission-cli: torrent client. run: transmission-cli [file]
echo cmatrix: matrix screen saver. run: cmatrix
echo cowsay: speech bubble with a cow. run: cowsay [text]
echo bmon: network bandwidth monitor. run: bmon
echo screenfetch: system info display. run: screenfetch
echo morse: converts text to morse code. run: morse [text]
echo watch: runs commands repeatedly. run: watch [command]
echo cal: displays a calendar. run: cal
echo bb: ascii art demo. run: bb
echo pipes.sh: fun terminal animation. run: pipes.sh
echo figlet: ascii text generator. run: figlet [text]
echo lolcat: fun text generator. run: lolcat [text]
echo toilet: text generator with fonts. run: toilet [text]
echo asciiquarium: ascii fish tank. run: asciiquarium

pause
goto packages

:installed
cls

choco list

pause

:f

echo faggot

pause

:systeminfo
cls

systeminfo | more

pause
goto :extra

:uninstallchoco
choco uninstall chocolatey -y

rd /s /q C:\ProgramData\Chocolatey

setx PATH "%PATH:C:\ProgramData\Chocolatey\bin;=%"

echo chocolatey has been uninstalled successfully.
pause
goto :extra

:terminal
cls
echo input menu to go back to batch
goto :realterminal

:realterminal

set /p "devinput=%cd%>"

if "%devinput%"=="menu" goto :menu

%devinput%

call :realterminal




