function Get-NewDotNetProjectCommand {
  $templates = & dotnet new list --type project 2>$null
  if (-not $templates) {
    Write-Host "Failed to get template list" -ForegroundColor Red
    return
  }

  $templateList = @()
  $parsing = $false

  foreach ($line in $templates) {
    if ($parsing -and $line.Trim() -and $line -match '^(.+?)\s{2,}(\S+)\s{2,}(.+?)\s{2,}') {
      $templateList += [PSCustomObject]@{
        Display = "{0,-45} {1,-15} {2}" -f $Matches[1].Trim(), $Matches[2].Trim(), $Matches[3].Trim()
        ShortName = $Matches[2].Trim()
      }
    }
    elseif ($line -match '^-{3,}') { # Ignore the header line
      $parsing = $true
    }
  }

  if ($templateList.Count -eq 0) {
    Write-Host "No project templates found" -ForegroundColor Yellow
    return
  }

  # Select template with fzf
  $selected = $templateList.Display | fzf --header="Select Project Template" --height=20 --layout=reverse
  if (-not $selected) { return }

  $template = $templateList | Where-Object { $_.Display -eq $selected } | Select-Object -First 1
  $shortName = ($template.ShortName -split ',')[0]

  $projectName = Read-Host "Project name"
  if (-not $projectName) { return }

  $directory = Read-Host "Directory (leave empty to use current directory)"

  # Build command
  if ($directory) {
    return "dotnet new $shortName --name `"$projectName`" --output `"$directory`""
  } else {
    return "dotnet new $shortName --name `"$projectName`""
  }
}

function New-DotNetProject {
  $command = Get-NewDotNetProjectCommand
  if ($command) {
    Invoke-Expression $command
  }
}
Set-Alias -Name dnp -Value New-DotNetProject

function New-DotNetItem {
  $templates = & dotnet new list --type item 2>$null
  if (-not $templates) {
    Write-Host "Failed to get template list" -ForegroundColor Red
    return
  }

  $templateList = @()
  $parsing = $false

  foreach ($line in $templates) {
    if ($parsing -and $line.Trim() -and $line -match '^(.+?)\s{2,}(\S+)\s{2,}(.+?)\s{2,}') {
      $templateList += [PSCustomObject]@{
        Display = "{0,-45} {1,-15} {2}" -f $Matches[1].Trim(), $Matches[2].Trim(), $Matches[3].Trim()
        ShortName = $Matches[2].Trim()
      }
    }
    elseif ($line -match '^-{3,}') { # Ignore the header line
      $parsing = $true
    }
  }

  if ($templateList.Count -eq 0) {
    Write-Host "No item templates found" -ForegroundColor Yellow
    return
  }

  # Select template with fzf
  $selected = $templateList.Display | fzf --header="Select Item Template" --height=20 --layout=reverse
  if (-not $selected) { return }

  $template = $templateList | Where-Object { $_.Display -eq $selected } | Select-Object -First 1
  $shortName = ($template.ShortName -split ',')[0]

  $itemName = Read-Host "Item name"
  if (-not $itemName) { return }

  Write-Host "Creating item: dotnet new $shortName --name `"$itemName`"" -ForegroundColor Cyan
  & dotnet new $shortName --name "$itemName"

  if ($LASTEXITCODE -eq 0) {
    Write-Host "Item created successfully: $itemName" -ForegroundColor Green
    Open-Item $itemName
  } else {
    Write-Host "Failed to create item" -ForegroundColor Red
  }
}

function Open-Item {
  param (
    [string]$ItemName
  )

  $newFiles = Get-ChildItem -Path . -Filter "$ItemName*" -File -ErrorAction SilentlyContinue
  if ($newFiles) {
    $foundFile = $newFiles[0].Name
    Write-Host "Opening file: $foundFile" -ForegroundColor Green

    if ($env:EDITOR) {
      & $env:EDITOR $foundFile
    } else {
      Write-Host "File created: $foundFile (no editor found to open it)" -ForegroundColor Yellow
    }
  }
}
Set-Alias -Name dni -Value New-DotNetItem

function Get-DotNetCommand {
  $menuItems = @(
    @{ Name = "Build"; Cmd = "dotnet build"; Desc = "Build the project" },
    @{ Name = "Build (Release)"; Cmd = "dotnet build -c Release"; Desc = "Build in Release mode" },
    @{ Name = "Rebuild"; Cmd = "dotnet clean && dotnet build"; Desc = "Clean and build" },
    @{ Name = "Clean"; Cmd = "dotnet clean"; Desc = "Clean build outputs" },
    @{ Name = "Restore"; Cmd = "dotnet restore"; Desc = "Restore dependencies" },
    @{ Name = "Run"; Cmd = "dotnet run"; Desc = "Run the project" },
    @{ Name = "Run (Release)"; Cmd = "dotnet run -c Release"; Desc = "Run in Release mode" },
    @{ Name = "Test"; Cmd = "dotnet test"; Desc = "Run tests" },
    @{ Name = "Watch Run"; Cmd = "dotnet watch run"; Desc = "Run with file watcher" },
    @{ Name = "Watch Test"; Cmd = "dotnet watch test"; Desc = "Test with file watcher" }
  )

  $selection = $menuItems | ForEach-Object { "$($_.Name) : $($_.Desc)" } | fzf --prompt "🚀 DotNet Commands > "

  if ($null -ne $selection) {
    # Extract the selected command name (everything before " : ")
    $selectedName = $selection -split ' : ' | Select-Object -First 1

    return $menuItems | Where-Object { $_.Name -eq $selectedName } | Select-Object -First 1
  }
}

function Invoke-DotNetCommand {
  $selection = Get-DotNetCommand

  if ($selection) {
    Invoke-Expression $selection.cmd
  } else {
    Write-Host "Could not find any menu item with the selection: $selectedName" -ForegroundColor Red
  }
}

Set-Alias dn Invoke-DotNetCommand
Set-Alias dnc Invoke-DotNetCommand
