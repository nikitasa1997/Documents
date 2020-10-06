Set-StrictMode -Version Latest

$DefaultLUID = '00000000'

$Path = '\Users\nikit\Downloads\Documents\Windows 10\Services\services.json'
$Encoding = 'utf8'

$Service = Get-Service |
    Select-Object -Property Name, ServiceType, StartType
$PerUserServices = $Service |
    Where-Object -Property ServiceType -In -Value @(224, 240) |
    Select-Object -ExpandProperty Name
$LUID = $PerUserServices |
    Foreach-Object -Process {$_ -replace '^.+_([0-9a-f]{4,8})$', '$1'} |
    Sort-Object -Unique
$Service += $PerUserServices |
    Foreach-Object -Process {$_ -replace "^(.+)_$LUID`$", '$1'} |
    Get-Service |
    Select-Object -Property Name, StartType

$Service |
    Sort-Object -Property Name |
    Foreach-Object -Begin {
        $Ordered = [ordered]@{}
    } -Process {
        $_.Name = $_.Name -replace "^(.+)_$LUID`$", "`$1_$DefaultLUID"
        $Ordered.Add($_.Name, $_.StartType)
    } -End {
        $Ordered
    } |
    ConvertTo-Json -Depth 1 |
    Set-Content -Path $Path -Encoding $Encoding
