Set-StrictMode -Version Latest

$Encoding = 'utf8'
$DefaultLUID = '00000000'

function ServiceTo-Json {
    Param(
        [string]$Path
    )
    process {
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
                $Ordered.Add(
                    ($_.Name -replace "^(.+)_$LUID`$", "`$1_$DefaultLUID"),
                    $_.StartType
                )
            } -End {
                $Ordered
            } |
            ConvertTo-Json -Depth 1 |
            Set-Content -Path $Path -Encoding $Encoding
    }
}

ServiceTo-Json('\Users\nikit\Downloads\Documents\Windows 10\Services\services.json')
