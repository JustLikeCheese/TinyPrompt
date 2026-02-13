param(
    [string]$Command,
    [string]$EmployeeId,
    [string]$Message
)

$RootDir = "$PSScriptRoot/.."
$BaseDir = "$RootDir/hidden/inbox"
$IndexFile = "$BaseDir/index.txt"
$MessageFile = "$BaseDir/message.json"
$IndexesDir = "$BaseDir/indexes"

function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Initialize-DataFiles {
    if (!(Test-Path $BaseDir)) {
        New-Item -ItemType Directory -Path $BaseDir -Force | Out-Null
    }
    if (!(Test-Path $IndexesDir)) {
        New-Item -ItemType Directory -Path $IndexesDir -Force | Out-Null
    }
    if (!(Test-Path $IndexFile)) {
        Write-Utf8NoBom -Path $IndexFile -Content "0`r`n"
    }
    if (!(Test-Path $MessageFile)) {
        Write-Utf8NoBom -Path $MessageFile -Content "[`r`n]`r`n"
    }
}

function New-EmployeeId {
    Initialize-DataFiles
    $currentId = [int](Get-Content $IndexFile)
    Write-Utf8NoBom -Path $IndexFile -Content "$(($currentId + 1))`r`n"
    Write-Host "Your employee id is $currentId!"
}

function Fetch-Messages {
    param(
        [string]$Id
    )
    Initialize-DataFiles
    $employeeIndexFile = "$IndexesDir/$Id.txt"
    if (!(Test-Path $employeeIndexFile)) {
        Write-Utf8NoBom -Path $employeeIndexFile -Content "0`r`n"
    }
    $lastRead = [int](Get-Content $employeeIndexFile)
    $content = Get-Content $MessageFile -Raw -Encoding UTF8
    $messages = $content | ConvertFrom-Json
    if ($messages.Count -gt $lastRead) {
        Write-Host "New Message:"
        for ($i = $lastRead; $i -lt $messages.Count; $i++) {
            Write-Host $messages[$i]
        }
        Write-Utf8NoBom -Path $employeeIndexFile -Content "$($messages.Count)`r`n"
    } else {
        Write-Host "No new messages for now. Please try again later."
    }
}

function Post-Message {
    param(
        [string]$Id,
        [string]$Content
    )
    Initialize-DataFiles
    $messagesList = New-Object System.Collections.ArrayList
    if (Test-Path $MessageFile) {
        $fileContent = Get-Content $MessageFile -Raw -Encoding UTF8
        if (![string]::IsNullOrEmpty($fileContent)) {
            try {
                $parsedContent = ConvertFrom-Json -InputObject $fileContent
                if ($parsedContent -is [array]) {
                    foreach ($msg in $parsedContent) {
                        [void]$messagesList.Add($msg)
                    }
                } elseif ($parsedContent -is [string]) {
                    if ($parsedContent -ne "[]") {
                        [void]$messagesList.Add($parsedContent)
                    }
                }
            } catch {
            }
        }
    }
    $newMessage = "${Id}: $Content"
    [void]$messagesList.Add($newMessage)

    $jsonLines = [System.Collections.Generic.List[string]]::new()
    $jsonLines.Add('[')
    for ($i = 0; $i -lt $messagesList.Count; $i++) {
        $msg = $messagesList[$i]
        $escapedMsg = $msg -replace '"', '\"'
        $line = '    "' + $escapedMsg + '"'
        if ($i -lt $messagesList.Count - 1) {
            $line += ','
        }
        $jsonLines.Add($line)
    }
    $jsonLines.Add(']')

    $jsonContent = ($jsonLines -join "`r`n") + "`r`n"
    Write-Utf8NoBom -Path $MessageFile -Content $jsonContent
}

switch ($Command) {
    "new" {
        New-EmployeeId
    }
    "fetch" {
        if ($EmployeeId) {
            Fetch-Messages -Id $EmployeeId
        } else {
            Write-Host "Error: Employee ID is required for fetch command"
        }
    }
    "post" {
        if ($EmployeeId -and $Message) {
            Post-Message -Id $EmployeeId -Content $Message
        } else {
            Write-Host "Error: Employee ID and Message are required for post command"
        }
    }
    default {
        Write-Host "Error: Invalid command. Available commands: new, fetch, post"
    }
}