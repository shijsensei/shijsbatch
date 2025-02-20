title shijs batch
wchcp 65001
@echo off
setlocal enabledelayedexpansion


color 5

if "%1"==":a" goto :a

:menu
mode 81,26
cls                                                                  
echo   ####    #    #   #        #    ####      #####     ##    #####   ####   #    #
echo  #        #    #   #        #   #          #    #   #  #     #    #    #  #    #
echo   ####    ######   #        #    ####      #####   #    #    #    #       ######
echo       #   #    #   #        #        #     #    #  ######    #    #       #    #
echo  #    #   #    #   #   #    #   #    #     #    #  #    #    #    #    #  #    #
echo   ####    #    #   #    ####     ####      #####   #    #    #     ####   #    #
echo.                                                                                    
echo you may press b at any point to come back to this menu
echo.
echo -1-shortcuts
echo -2-fetch
echo -3-terminal
echo -4-task manager
echo -5-miscellaneous            
set /p choice=

if /i "%choice%"=="1" call :shortcuts
if /i "%choice%"=="2" call :fetch
if /i "%choice%"=="3" call :terminal
if /i "%choice%"=="4" call :taskmanager
if /i "%choice%"=="5" call :extra
goto menu


:shortcuts
cls

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
echo input 'create' to add a new 
echo input 'delete (name)' to remove
echo input 'edit' to edit shorcuts.txt
echo ---------------

for /f "tokens=1 delims=;" %%a in (shortcuts.txt) do (
    echo %%a
)
echo ---------------
echo input shortcut name to open
echo input b to go back
set /p shortcut_choice=

if /i "%shortcut_choice%"=="create" (
    call :create_shortcut
    goto show_shortcuts
) else if "%shortcut_choice:~0,7%"=="delete " (
    call :delete_shortcut "%shortcut_choice:~7%"
    goto show_shortcuts
) else if /i "%shortcut_choice%"=="b" (
    goto menu
) else if /i "%shortcut_choice%"=="edit" (
    start notepad "%cd%\shortcuts.txt" & goto show_shortcuts
) else (
    call :open_shortcut "%shortcut_choice%"
    goto show_shortcuts
)

:create_shortcut
cls
set /p shortcut_name="enter shortcut name (type 'exit' to go back): "
if /i "%shortcut_name%"=="exit" goto show_shortcuts

set /p shortcut_path="enter the full path for the shortcut (type 'exit' to go back): "
if /i "%shortcut_path%"=="exit" goto show_shortcuts


findstr /x /c:"%shortcut_name%;%shortcut_path%" shortcuts.txt >nul
if %errorlevel%==0 (
    echo a shortcut with that name already exists.
    pause
    goto show_shortcuts
)


echo %shortcut_name%;%shortcut_path% >> shortcuts.txt
echo shortcut added successfully.

pause
goto show_shortcuts

:delete_shortcut
cls
set "delete_name=%~1"

:: check if shortcut exists before trying to delete
findstr /c:"%delete_name%;" shortcuts.txt >nul
if %errorlevel% neq 0 (
    echo shortcut '%delete_name%' not found.
    pause
    goto show_shortcuts
)


findstr /v /c:"%delete_name%;" shortcuts.txt > temp.txt
move /y temp.txt shortcuts.txt >nul
echo shortcut '%delete_name%' deleted.
pause
goto show_shortcuts

:open_shortcut
cls
set "shortcut_name=%~1"

:: find the shortcut path
for /f "tokens=1,2 delims=;" %%a in (shortcuts.txt) do (
    if /i "%%a"=="%shortcut_name%" (
        if exist "%%b" (
            start explorer "%%b"
        ) else (
            echo shortcut path not found: %%b
            pause
        )
        goto show_shortcuts
    )
)

echo shortcut not found.
pause
goto show_shortcuts

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

:: ram usage (used and free)
for /f "tokens=2 delims==" %%a in ('wmic os get freephysicalmemory /value') do set "freeram=%%a"
for /f "tokens=2 delims==" %%a in ('wmic os get totalvisiblememorysize /value') do set "totalram=%%a"

if not defined totalram (
    echo failed to retrieve total ram.
    pause
    exit /b
)

if not defined freeram (
    echo failed to retrieve free ram.
    pause
    exit /b
)

set /a "usedram=%totalram% - %freeram%"
set /a "freerammb=%freeram% / 1024"
set /a "usedrammb=%usedram% / 1024"

echo used ram: %usedrammb% mb
echo free ram: %freerammb% mb

:: gpu information using powershell
for /f "tokens=*" %%a in ('powershell -command "get-wmiobject win32_videocontroller | select-object -expandproperty caption"') do (
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

:: convert times to total minutes since a reference point
set /a lastbootminutes=(1!lastbootyear:~2,2! * 525600) + (1!lastbootmonth! * 43800) + (1!lastbootday! * 1440) + (1!lastboothour! * 60) + 1!lastbootminute!
set /a currentminutes=(1!currentyear:~2,2! * 525600) + (1!currentmonth! * 43800) + (1!currentday! * 1440) + (1!currenthour! * 60) + 1!currentminute!

set /a uptime_minutes=currentminutes - lastbootminutes
set /a uptime_days=uptime_minutes / 1440
set /a uptime_hours=(uptime_minutes %% 1440) / 60
set /a uptime_remaining_minutes=uptime_minutes %% 60

for /f %%a in ('echo prompt $H ^| findstr "."') do set "CR=%%a"

:fetching
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
echo gpu: !gpu!
echo total ram: !ramoutput!
echo used ram: %usedrammb% mb
echo free ram: %freerammb% mb
echo architecture: !arch!
echo motherboard: !pcmodel!

echo screen resolution: !width! x !height!
echo boot time: !boottime!

:uptimeloop
echo uptime: %uptime_days% days, %uptime_hours% hours, %uptime_remaining_minutes% minutes

choice /c b /n
if errorlevel 1 goto menu

goto :fetching

:matrix
color 0a

echo press any key
timeout /t 99999 >nul


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
mode 152,50
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
pause > nul  rem 

choice /c b /n
if errorlevel 1 goto extra

goto ascii

:cmd
cls

start cmd /k "echo cmd succsesfully opened"

goto extra

:internet

:check_connection
echo.
echo please wait... checking internet connection...
timeout /t 1 /nobreak >nul
ping www.google.com -n 1 -w 1000 >nul && set "internet=connected" || set "internet=not connected"

for /f "tokens=14" %%i in ('ipconfig ^| findstr /i "ipv4"') do set localip=%%i

for /f "delims=" %%i in ('curl -s https://api.ipify.org') do set publicip=%%i

echo your local ip address is: %localip%
echo your public ip address is: %publicip%

timeout /t 99999 >nul
goto extra

:refresh
echo refreshing icon cache...
taskkill /im explorer.exe /f
del /a:h "%localappdata%\microsoft\windows\explorer\iconcache*" >nul 2>&1
start explorer.exe
echo icon cache refreshed.
timeout /t 99999 >nul
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
set /p fgchoice=


echo select a background color
echo -1- black
echo -2- red
echo -3- green
echo -4- yellow
echo -5- blue
echo -6- magenta
echo -7- cyan
echo -8- white
set /p bgchoice=


if "%fgchoice%"=="b" goto :extra
if "%fgchoice%"=="1" set fgcolor=0
if "%fgchoice%"=="2" set fgcolor=4
if "%fgchoice%"=="3" set fgcolor=2
if "%fgchoice%"=="4" set fgcolor=6
if "%fgchoice%"=="5" set fgcolor=1
if "%fgchoice%"=="6" set fgcolor=5
if "%fgchoice%"=="7" set fgcolor=3
if "%fgchoice%"=="8" set fgcolor=7

if "%bgchoice%"=="b" goto :extra
if "%bgchoice%"=="1" set bgcolor=0
if "%bgchoice%"=="2" set bgcolor=4
if "%bgchoice%"=="3" set bgcolor=2
if "%bgchoice%"=="4" set bgcolor=6
if "%bgchoice%"=="5" set bgcolor=1
if "%bgchoice%"=="6" set bgcolor=5
if "%bgchoice%"=="7" set bgcolor=3
if "%bgchoice%"=="8" set bgcolor=7

color %bgcolor%%fgcolor%

cls
echo you have selected text color %fgchoice% and background color %bgchoice%.


choice /c b /n
if errorlevel 1 goto extra

pause
goto extra

:taskmanager
mode 81,26

:taskmenu
cls
echo          windows 95 task manager
echo [b]menu
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

echo [b]back
echo [k]kill process
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


for /f "tokens=2 delims==" %%a in ('wmic cpu get loadpercentage /value') do set cpu=%%a

for /f "tokens=2 delims==" %%a in ('wmic os get freephysicalmemory /value') do set freeram=%%a
for /f "tokens=2 delims==" %%a in ('wmic os get totalvisiblememorysize /value') do set totalram=%%a
set /a usedram=%totalram% - %freeram%
set /a freerammb=%freeram% / 1024
set /a usedrammb=%usedram% / 1024
set /a totalrammb=%totalram% / 1024

echo ==============================================
echo  cpu usage: %cpu%%  
echo  ram usage: %usedrammb%mb / %totalrammb%mb  
echo ==============================================

:: wait 1 second before refreshing the data
ping -n 2 127.0.0.1 >nul

goto :a

:killprocess
cls

echo               kill process by name
echo enter the name of the process to kill (e.g., notepad.exe):
set /p processname=process: 

taskkill /im "%processname%" /f >nul 2>&1

if %errorlevel%==0 (
    echo process "%processname%" has been killed.
) else (
    echo failed to kill process "%processname%" or it may not exist.
)

choice /c b /n
if errorlevel 1 goto taskmenu

:packages

echo -b-back
echo -1-install choco (package manager) [need to run batch as admin]
echo -2-install packages                [need to run batch as admin]
echo -3-usage      
echo -4-check packages                  [need to run batch as admin]
echo -5-uninstall choco                 [need to run batch as admin]
echo. 
echo packages are listed in  "usage"
set /p choice=


if /i "%choice%"=="b" call :extra
if /i "%choice%"=="1" call :choco
if /i "%choice%"=="2" call :installpgk
if /i "%choice%"=="3" call :usage
if /i "%choice%"=="4" call :installed
if /i "%choice%"=="5" call :uninstallchoco


goto packages

:choco
cls
net session >nul 2>&1 || goto notadmin
echo running as admin...

echo opening powershell to enable script execution and install chocolatey...

powershell -noexit -command ^
"set-executionpolicy remotesigned -scope currentuser -force; ^
iex ((new-object system.net.webclient).downloadstring('https://community.chocolatey.org/install.ps1')); ^
[system.environment]::setenvironmentvariable('path', $env:path + ';c:\programdata\chocolatey\bin', [system.environmentvariabletarget]::user); ^
echo installation complete. please restart your command prompt."

pause 

:installpgk
cls
net session >nul 2>&1 || goto notadmin
echo running as admin...

echo oopening powershell to install packages with chocolatey...
echo this may take some time depending on your internet speed.

rem run powershell script to install packages via chocolatey directly
powershell -command "
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
    choco install vim -y --confirm --accept-license --no-progress;
    choco install ranger -y --confirm --accept-license --no-progress;
"

echo installation process completed
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

timeout /t 99999 >nul

goto packages

:installed
cls

choco list

timeout /t 99999 >nul
goto packages

:f

echo faggot

timeout /t 99999 >nul


:systeminfo
mode 94,52
cls

systeminfo 

timeout /t 99999 >nul

goto :extra

:uninstallchoco
net session >nul 2>&1 || goto notadmin
echo running as admin...

choco uninstall chocolatey -y

rd /s /q c:\programdata\chocolatey

setx path "%path:c:\programdata\chocolatey\bin;=%"

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

:windows
mode 94,500
cls  
echo alt + enter  ^- fullscreen for command prompt  
echo alt + esc  ^- cycle through open windows  
echo alt + f4  ^- close active window/shutdown pc  
echo alt + left arrow  ^- go back in file explorer  
echo alt + right arrow  ^- go forward in file explorer  
echo alt + space  ^- open window menu  
echo alt + tab  ^- switch between open windows  
echo ctrl + a  ^- select all  
echo ctrl + alt + delete  ^- open security options  
echo ctrl + alt + esc  ^- open task manager directly  
echo ctrl + alt + up arrow  ^- rotate screen to normal  
echo ctrl + alt + down arrow  ^- rotate screen upside down  
echo ctrl + alt + left arrow  ^- rotate screen left  
echo ctrl + alt + right arrow  ^- rotate screen right  
echo ctrl + b  ^- bold text (in some apps)  
echo ctrl + c  ^- copy selected text  
echo ctrl + d  ^- delete selected file  
echo ctrl + e  ^- focus on search bar in file explorer  
echo ctrl + f  ^- find text in most applications  
echo ctrl + h  ^- open history in some browsers  
echo ctrl + i  ^- italic text (in some apps)  
echo ctrl + l  ^- highlight address bar in browsers  
echo ctrl + m  ^- enter move mode in command prompt  
echo ctrl + n  ^- open a new window in some apps  
echo ctrl + p  ^- print  
echo ctrl + r  ^- refresh the page  
echo ctrl + s  ^- save file  
echo ctrl + shift + esc  ^- open task manager  
echo ctrl + shift + n  ^- create new folder  
echo ctrl + v  ^- paste  
echo ctrl + w  ^- close current tab  
echo ctrl + x  ^- cut selected text or file  
echo ctrl + y  ^- redo last action  
echo ctrl + z  ^- undo last action  
echo f1  ^- open help  
echo f2  ^- rename selected file  
echo f3  ^- open search in file explorer  
echo f4  ^- focus on address bar in file explorer  
echo f5  ^- refresh page or folder  
echo f6  ^- cycle through elements in a window  
echo f10  ^- activate menu bar in some apps  
echo home  ^- move to beginning of line  
echo end  ^- move to end of line  
echo shift + delete  ^- permanently delete file  
echo shift + f10  ^- open right-click menu  
echo shift + tab  ^- move focus backward  
echo tab  ^- move focus forward  
echo windows + 1-9  ^- open taskbar programs by position  
echo windows + a  ^- open action center  
echo windows + ctrl + d  ^- create new virtual desktop  
echo windows + ctrl + left/right  ^- switch virtual desktops  
echo windows + ctrl + f4  ^- close virtual desktop  
echo windows + d  ^- show desktop  
echo windows + e  ^- open file explorer  
echo windows + g  ^- open game bar  
echo windows + h  ^- open voice typing  
echo windows + i  ^- open settings  
echo windows + k  ^- open connect menu  
echo windows + l  ^- lock computer  
echo windows + m  ^- minimize all windows  
echo windows + p  ^- project screen settings  
echo windows + r  ^- open run dialog  
echo windows + s  ^- open search  
echo windows + shift + s  ^- take screenshot (snipping tool)  
echo windows + t  ^- cycle through taskbar programs  
echo windows + u  ^- open accessibility settings  
echo windows + v  ^- open clipboard history  
echo windows + x  ^- open quick link menu  
echo windows + .  ^- open emoji panel  
echo windows + space  ^- switch keyboard language  
echo windows + tab  ^- open task view  

pause
goto extra


:ddr
echo note that anything above ddr2 cannot be displayed

set foundddr=0

for /f "skip=1" %%a in ('wmic memorychip get memorytype 2^>nul') do (
    set "ramtype=%%a"
    
    if "!ramtype!"=="20" (
        echo  ram type is ddr
        set foundddr=1
    )
    if "!ramtype!"=="21" (
        echo  ram type is ddr2
        set foundddr=1
    )
)

if "!foundddr!"=="0" (
    echo your ram type is ddr3 or higher
)

timeout /t 10 >nul

goto :extra

:advanced 
net session >nul 2>&1 || goto notadmin
echo running as admin...

cls

echo -b- back
echo.
echo -s- system backup 
echo.
echo -r- repair system
echo.
echo -d- date and time configuration 
echo.
echo -p- power options 
set /p choice=

if /i "%choice%"=="b" call :extra
if /i "%choice%"=="s" call :backup 
if /i "%choice%"=="r" call :repair 
if /i "%choice%"=="d" call :date   
if /i "%choice%"=="p" call :power
goto :advanced

:backup
net session >nul 2>&1 || goto notadmin
echo running as admin...

echo enter the path of the folder or drive to copy (e.g., c:\, d:\, or any folder path)
set /p source=


if not exist "%source%" (
    echo source path does not exist.
    goto :advanced
)


echo enter the destination directory (e.g., e:\ or any folder path)
set /p destination=


if not exist "%destination%" (
    echo destination path does not exist.
    goto :advanced
)

echo choose backup type:
echo f folder
echo z zip file
set /p backuptype=

if "%backuptype%"=="f" goto :backup_folder
if "%backuptype%"=="z" goto :backup_zip

echo invalid selection.
goto :backup

:backup_folder
echo name the folder
set /p foldername=
mkdir "%destination%\%foldername%"

echo copying files from "%source%" to "%destination%\%foldername%" in 5 seconds
echo hit ctrl + c to cancel
timeout /t 1 >nul
echo 5
timeout /t 1 >nul
echo 4
timeout /t 1 >nul
echo 3
timeout /t 1 >nul
echo 2
timeout /t 1 >nul
echo 1

echo on

xcopy "%source%" "%destination%\%foldername%" /e /h /y

echo off

echo operation completed

pause
goto :advanced

:backup_zip
echo name the zip file (without extension)
set /p foldername=

echo creating zip file "%destination%\%foldername%.zip"...
powershell compress-archive -path "%source%\*" -destinationpath "%destination%\%foldername%.zip"

echo zip operation completed

pause
goto :advanced


:repair
net session >nul 2>&1 || goto notadmin
echo running as admin...

echo on
sfc /scannow
echo off
timeout /t 999 >nul
goto :advanced

:notadmin
echo this script requires admin privileges!
timeout /t 9999 >nul
goto :extra

:date
net session >nul 2>&1 || goto notadmin
echo running as admin...

echo the date and time is %date% %time%
echo change? (y/n)
set /p choice=
if /i "%choice%" neq "y" goto :advanced

for /f "tokens=1 delims=/.- " %%a in ("%date%") do set delf=%%a
set /a delf=%delf% 2>nul
if %delf% gtr 12 (set fmt=ddmmyyyy) else (set fmt=mmddyyyy)

echo enter new date:
if "%fmt%"=="ddmmyyyy" (
    echo format: dd-mm-yyyy
) else (
    echo format: mm-dd-yyyy
)
set /p newdate=
date %newdate%

echo enter new time (hh:mm:ss):
set /p newtime=
time %newtime%

timeout /t 999 >nul
goto :advanced

:power
echo b back
echo s shutdown
echo z zzzzzz
echo r restart
set /p option=

if "%option%"=="s" goto :off
if "%option%"=="z" goto :sleep
if "%option%"=="r" goto :restart
if "%option%"=="b" goto :advanced

goto :power

:off
echo on
shutdown /s /f /t 0

:restart
echo on
shutdown /r /f /t 0

:sleep
powercfg -hibernate off
rundll32.exe powrprof.dll,setsuspendstate 0,1,0
powercfg -hibernate on
goto :power

:update
echo checking for updates from https://github.com/shijsensei/shijsbatch

curl -s https://api.github.com/repos/shijsensei/shijsbatch/releases/latest > latest_release.json

for /f "delims=: tokens=2" %%a in ('findstr /i "tag_name" latest_release.json') do set latest_version=%%a

set latest_version=%latest_version:"=%
set latest_version=%latest_version:,=%
for /f "tokens=* delims= " %%b in ("%latest_version%") do set latest_version=%%b

set current_version=1
set current_version=%current_version: =%

echo current_version: %current_version%
echo latest_version: %latest_version%

del latest_release.json

if "%current_version%"=="%latest_version%" (
    echo no update yet :(
) else (
    echo new release found! opening release in browser...
    start https://github.com/shijsensei/shijsbatch/releases/latest
)
timeout /t 9999 >nul
goto :extra

:elevate
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo requesting administrator privileges
    powershell -command "start-process cmd -argumentlist '/c \"%~f0\"' -verb runas"
    exit
)

goto extra

:close
exit



:batchoptions
echo -b- back
echo -1- toggle echo
echo -2- jump section
set /p option=

if /i "%option%"=="1" call :toggleecho
if /i "%option%"=="2" call :jumpsection
if /i "%option%"=="B" call :extra

goto :batchoptions

:toggleecho
echo -1- on
echo -2- off
set /p option=

if /i "%option%"=="1" (
    @echo on
)
if /i "%option%"=="2" (
    @echo off
)

goto batchoptions

:jumpsection
cls
echo input goto (section)

goto batchoptions

:extra
mode 81,26
cls

echo -0- advanced tools [need admin]
echo -1- open cmd
echo -2- packages
echo -3- test internet connection
echo -4- colors
echo -5- refresh icon cache
echo -6- ascii hanekawa art
echo -7- matrix
echo -8- display all system info
echo -9- collect pc data
echo -10- all windows hotkeys
echo -11- check ddr
echo.
echo -b- menu
echo -u- update shijsbatch
echo -e- elevate to admin
echo -x- close
set /p choice=


if /i "%choice%"=="b" call :menu
if /i "%choice%"=="u" call :update
if /i "%choice%"=="e" call :elevate
if /i "%choice%"=="x" call :close
if /i "%choice%"=="0" call :advanced
if /i "%choice%"=="1" call :cmd
if /i "%choice%"=="2" call :packages
if /i "%choice%"=="3" call :internet
if /i "%choice%"=="4" call :colors
if /i "%choice%"=="5" call :refresh
if /i "%choice%"=="6" call :ascii
if /i "%choice%"=="7" call :matrix
if /i "%choice%"=="8" call :systeminfo
if /i "%choice%"=="9" call :collect
if /i "%choice%"=="10" call :windows
if /i "%choice%"=="11" call :ddr
if /i "%choice%"=="12" call :batchoptions
goto extra

:rdp
