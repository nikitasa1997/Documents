Set-StrictMode -Version Latest

$DefaultLUID = '00000000'

$Path = '\Users\nikit\Downloads\services.json'
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
        $Ordered.Add(($_.Name -replace "^(.+_)$LUID`$", "`$1_$DefaultLUID"), $_.StartType)
    } -End {
        $Ordered
    } |
    ConvertTo-Json -Depth 1 |
    Set-Content -Path $Path -Encoding $Encoding








# $Service | select Name | -replace '^.+?_', '' | Sort-Object -Unique
#function svcsuffix `%@word["_",1,%@execstr[wmiquery /a . "select Name from Win32_Service" | ffind /k /m /e"_[0-9a-f]+$"]]`
#echo %@svcsuffix[]
