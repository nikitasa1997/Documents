Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

[string]$DefaultLUID = '00000000'
[string]$Encoding = 'UTF8'

function Get-ServiceAsArray {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param()
    begin {
        [string]$Pattern = '^(.+)_[0-9a-f]{4,8}$'
    }
    process {
        [hashtable]$Service96 = @{}
        [pscustomobject[]]$Service = Get-Service |
            Select-Object -Property @{Name = 'Name'; Expression = {
                if ($_.ServiceType -in @(224, 240)) {
                    $_.Name -match $Pattern -as [void]
                    # [void]($_.Name -match $Pattern)
                    $Service96.Add($Matches[1], $null)
                    "$($Matches[1])_$DefaultLUID"
                } else {$_.Name}
            }}, StartType
        $Service + (Get-Service -Name @($Service96.Keys)) |
            Select-Object -Property Name, @{Name = 'Value'; Expression = {
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
        $Array = Get-Content -Path $Path -Encoding $Encoding |
            ConvertFrom-Json
        $Array.PSObject.Properties |
            Foreach-Object -Process {[pscustomobject]@{
                Name = $_.Name
                Value = $_.Value
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
            $_.PSObject.Properties.Name.Count -eq 2 -and
            $_.Name -is [string] -and
            $_.Value -is [string] -and
            $_.Value -in @('Automatic', 'Disabled', 'Manual')
        })]
        [pscustomobject[]]
        $Service
    )
    begin {
        [string]$Pattern = "^(.+)_$DefaultLUID`$"
    }
    process {
        [int]$Position = 0
        foreach ($_ in Get-ServiceAsArray) {
            if (
                $Position -ge $Service.Count -or
                $_.Name -gt $Service[$Position].Name
            ) {
                break
            } elseif ($_.Name -lt $Service[$Position].Name) {
                continue
            } elseif ($_.Value -ne $Service[$Position].Value) {
                Set-Service -Name $(if ($_.Name -match $Pattern) {
                    Get-Service -Name "$($Matches[1])_*"
                } else {$_}).Name -StartupType $Service[$Position].Value
            }
            ++$Position
        }
        if ($Position -lt $Service.Count) {
            throw "No such service: $($Service[$Position].Name)"
        }
    }
}

function Stop-DisabledService {
    [CmdletBinding()]
    [OutputType()]
    param()
    process {
        Get-Service |
            Where-Object -FilterScript {
                $_.StartType -eq 'Disabled' -and $_.Status -ne 'Stopped'
            } |
            Stop-Service -Force
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
            $_.PSObject.Properties.Name.Count -eq 2 -and
            $_.Name -is [string] -and
            $_.Value -is [string] -and
            $_.Value -in @('Automatic', 'Disabled', 'Manual')
        })]
        [pscustomobject[]]
        $Array
    )
    process {
        $Array |
            Foreach-Object -Begin {$Ordered = [ordered]@{}} -Process {
                $Ordered.Add($_.Name, $_.Value)
            } -End {$Ordered} |
            ConvertTo-Json -Depth 1 |
            Set-Content -Path $Path -Encoding $Encoding
    }
}

[string]$Path = Join-Path `
    -Path $PSScriptRoot `
    -ChildPath 'services.json' `
    -Resolve
# [pscustomobject[]]$Service = Get-ServiceAsArray
# Write-ArrayToJsonFile -Path $Path -Array $Service
[pscustomobject[]]$Service = Read-ArrayFromJsonFile -Path $Path
Set-ServiceFromArray -Service $Service
Stop-DisabledService
