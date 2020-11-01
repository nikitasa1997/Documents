@ECHO OFF

WMIC SERVICE WHERE 'name = "XTU3SERVICE"' CALL ChangeStartmode Auto
WMIC SERVICE WHERE 'name = "XTU3SERVICE"' CALL StartService
TIMEOUT 4 /NOBREAK
"C:\Program Files (x86)\Intel\Intel(R) Extreme Tuning Utility\Client\XTUCli.exe" -t -id 34 -v -165
TIMEOUT 4 /NOBREAK
"C:\Program Files (x86)\Intel\Intel(R) Extreme Tuning Utility\Client\XTUCli.exe" -t -id 79 -v -165
TIMEOUT 4 /NOBREAK
"C:\Program Files (x86)\Intel\Intel(R) Extreme Tuning Utility\Client\XTUCli.exe" -t -id 83 -v -160
TIMEOUT 4 /NOBREAK
"C:\Program Files (x86)\Intel\Intel(R) Extreme Tuning Utility\Client\XTUCli.exe" -t -id 100 -v -160
TIMEOUT 4 /NOBREAK
WMIC SERVICE WHERE 'name = "XTU3SERVICE"' CALL StopService
WMIC SERVICE WHERE 'name = "XTU3SERVICE"' CALL ChangeStartmode Disabled
