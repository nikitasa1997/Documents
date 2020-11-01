Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

[string]$Encoding = 'UTF8'

function Get-ServiceAsArray {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param()
    begin {
        [string]$DefaultLUID = '00000000'
        [string]$Pattern = '^(.+)_[0-9a-f]{4,8}$'
    }
    process {
        [hashtable]$Service96 = @{}
        [pscustomobject[]]$Service = Get-Service |
            Select-Object -Property @{Name = 'Name'; Expression = {
                if ($_.ServiceType -in @(224, 240)) {
                    $Service96.Add(($_.Name -replace $Pattern, '$1'), $null)
                    $_.Name -replace $Pattern, "`$1_$DefaultLUID"
                } else {$_.Name}
            }}, StartType
        $Service + (Get-Service -Name @($Service96.Keys)) |
            Select-Object -Property Name, @{Name = 'StartType'; Expression = {
                [string]$_.StartType
            }} |
            Sort-Object -Property Name
    }
}

function Read-ArrayFromJsonFile {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [Parameter(
            Mandatory=$true,
            Position=0,
            ValueFromPipeline=$false,
            ValueFromPipelineByPropertyName=$true,
            ValueFromRemainingArguments=$false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^.*\.json$')]
        [ValidateScript({Test-Path `
            -Path $_ `
            -Filter '*.json' `
            -Include '*.json' `
            -PathType Leaf
        })]
        [string]
        $Path
    )
    process {
        $Service = Get-Content -Path $Path -Encoding $Encoding |
            ConvertFrom-Json
        $Service.PSObject.Properties |
            Foreach-Object -Process {[pscustomobject]@{
                Name = $_.Name
                StartType = $_.Value
            }} |
            Sort-Object -Property Name
    }
}

function Set-ServiceFromArray {
    [CmdletBinding()]
    [OutputType()]
    param(
        [Parameter(
            Mandatory=$true,
            Position=1,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ValueFromRemainingArguments=$false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            $_.PSObject.Properties.Name.Count -eq 2 -and `
            $_.Name -is [string] -and `
            $_.StartType -is [string] -and `
            $_.StartType -in @('Automatic', 'Disabled', 'Manual')
        })]
        [pscustomobject[]]
        $Service
    )
    process {
        $CurrentService = Get-ServiceAsArray
        [int]$Position = 0
        echo ('Count = ' + $Service.Count)
        foreach ($_ in $CurrentService) {
            echo ('Position = ' + $Position)
            if (
                $Position -ge $Service.Count -or
                $Service[$Position].Name -lt $_.Name
            ) {
                echo 'break'
                break
            } elseif ($Service[$Position].Name -gt $_.Name) {
                echo 'continue'
                continue
            }
            elseif (
                $Service[$Position].Name -eq $_.Name -and
                $Service[$Position].StartType -ne $_.StartType
            ) {
                echo ('Set-Service ' + $_.Name)
                Set-Service `
                    -Name $Service[$Position].Name `
                    -StartupType $Service[$Position].StartType
            }
            ++$Position
        }
        if ($Position -lt $CurrentService.Count) {
            throw 'No such service ' + $CurrentService[$Position].Name
        }
    }
}

function Write-ArrayToJsonFile {
    [CmdletBinding()]
    [OutputType()]
    param(
        [Parameter(
            Mandatory=$true,
            Position=0,
            ValueFromPipeline=$false,
            ValueFromPipelineByPropertyName=$true,
            ValueFromRemainingArguments=$false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^.*\.json$')]
        [ValidateScript({Test-Path `
            -Path $_ `
            -Filter '*.json' `
            -Include '*.json' `
            -PathType Leaf `
            -IsValid
        })]
        [string]
        $Path,
        [Parameter(
            Mandatory=$true,
            Position=1,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ValueFromRemainingArguments=$false
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            $_.PSObject.Properties.Name.Count -eq 2 -and `
            $_.Name -is [string] -and `
            $_.StartType -is [string] -and `
            $_.StartType -in @('Automatic', 'Disabled', 'Manual')
        })]
        [pscustomobject[]]
        $Service
    )
    process {
        $Service |
            Foreach-Object -Begin {$Ordered = [ordered]@{}} -Process {
                $Ordered.Add($_.Name, $_.StartType)
            } -End {$Ordered} |
            ConvertTo-Json -Depth 1 |
            Set-Content -Path $Path -Encoding $Encoding
    }
}

[string]$Path = '\Users\nikit\Downloads\Documents\Windows 10\Services\services.json'
[pscustomobject[]]$Service = Get-ServiceAsArray
Write-ArrayToJson -Path $Path -Service $Service
# [pscustomobject[]]$Service = Read-ArrayFromJson -Path $Path
# Set-ServiceFromArray -Service $Service
