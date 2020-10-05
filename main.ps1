$FilePath = "\Users\nikit\Downloads\services.json"
$Encoding = "utf8"

$Service = Get-Service
$Service |
    select -Property Name, StartType |
    foreach -Begin {
        $Ordered = [ordered]@{}
    } -Process {
        $Ordered.Add($_.Name, $_.StartType)
    } -End {
        $Ordered
    } |
    ConvertTo-Json -Depth 1 |
    Out-File -FilePath $FilePath -Encoding $Encoding

$Service = $Service | where ServiceType -in (224, 240) | select Name, StartType








$Service | select Name | -replace '^.+?_', '' | Sort-Object -Unique
function svcsuffix `%@word["_",1,%@execstr[wmiquery /a . "select Name from Win32_Service" | ffind /k /m /e"_[0-9a-f]+$"]]`
echo %@svcsuffix[]
