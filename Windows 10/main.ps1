$Service = Get-Service | Select Name, StartType | Group-Object -AsHashtable Name
$Service = Get-Service | Where ServiceType -eq 96 | Select Name, StartType
$Service = Get-Service | Where ServiceType -in (224, 240) | Select Name, StartType | Group-Object -AsHashtable
$Service | Select Name | -replace '^.+?_', '' | Sort-Object -Unique
