@echo off

	powershell -Command "Start-Process '%USERPROFILE%\Desktop\scripts\autosetup\test.bat' -Verb runAs"
	exit /b 0