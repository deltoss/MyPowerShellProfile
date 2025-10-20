function Get-Worktrees {
  $output = git worktree list --porcelain | Out-String
  $entries = $output -split '(\r?\n){2}' | Where-Object { $_.Trim() }

  if ($entries.Count -eq 0) {
    Write-Host "No worktrees found."
    return @()
  }

  # Get the first worktree's path (main repo)
  $mainRepoPath = ($entries[0] -split '\r?\n')[0] -replace '^worktree ', ''
  $parentPath = if (-not [string]::IsNullOrEmpty($mainRepoPath)) {
    Split-Path -Parent $mainRepoPath
  } else {
    $null
  }

  $entries | ForEach-Object {
    $lines = $_ -split '\r?\n' | Where-Object { $_ }
    $fullPath = $lines[0] -replace '^worktree ', ''

    if (-not [string]::IsNullOrEmpty($parentPath) -and -not [string]::IsNullOrEmpty($fullPath)) {
      try {
        $relativePath = [System.IO.Path]::GetRelativePath($parentPath, $fullPath)
      } catch {
        Write-Host "Failed to get relative path: $_"
        $relativePath = $fullPath
      }
    } else {
      $relativePath = $fullPath
    }

    [PSCustomObject]@{
      Path = $fullPath
      RelativePath = $relativePath
      Commit = $lines[1] -replace '^HEAD ', ''
      CommitShort = ($lines[1] -replace '^HEAD ', '').Substring(0, 7)
      Branch = if ($lines[2] -match '^branch ') {
        $lines[2] -replace '^branch refs/heads/', ''
      } else {
        '(detached)'
      }
    }
  }
}

function Select-WorktreeWithFzf {
  $worktrees = Get-Worktrees

  $formattedEntries = $worktrees |
    ForEach-Object {
      "{0,-40} {1,-10} {2}" -f $_.Branch, "($($_.CommitShort))", $_.RelativePath
    }

  $selected = $formattedEntries | fzf

  # fzf only gives us the selected string back
  # Get the original worktree object from the selection
  $selectedWorktree = $worktrees | Where-Object {
    $_.Branch -eq ($selected -replace '\s+\(.+\)\s+.+').Trim()
  }

  return $selectedWorktree
}

function Show-Worktree {
  $chosenWorktree = Select-WorktreeWithFzf
  if ($chosenWorktree) {
    Write-Host "Selected Worktree: $($chosenWorktree | Format-List | Out-String)" -ForegroundColor Green
  } else {
    Write-Host "No worktree was selected."
  }
}

function Switch-Worktree {
  $chosenWorktree = Select-WorktreeWithFzf
  if ($chosenWorktree) {
    Set-Location -Path $chosenWorktree.Path
    Write-Host "Switched to worktree: $($chosenWorktree.Path)" -ForegroundColor Green
  } else {
    Write-Host "No worktree was selected." -ForegroundColor Yellow
  }
}

function Create-Worktree {
  Read-Host -Prompt "Navigate Yazi to the directory you want the worktrees to be in. Press enter to continue..."
  $worktreePath = Get-PathWithYazi (Get-Location).Path

  Write-Host "Selected path: $worktreePath" -ForegroundColor Green

  $interaction = Select-GitBranch
  if (-not $interaction) {
    Write-Host "No branch was selected." -ForegroundColor Yellow
    return
  }

  $selectedBranch = $null
  $newBranch = $interaction.Query -and -not $interaction.Branch
  if ($newBranch) {
    $selectedBranch = $interaction.Query
    Write-Host "Will create new branch $selectedBranch." -ForegroundColor Green
  } else {
    $selectedBranch = $interaction.Branch -replace "^origin/", ""
  }

  $relativePath = Read-Host -Prompt "Enter the new worktree directory name (default: $selectedBranch)"
  if (-not $relativePath) {
    $relativePath = $selectedBranch
  }

  $fullPath = Join-Path $worktreePath $relativePath

  Write-Host "Creating worktree at: $fullPath" -ForegroundColor Green
  $result = $null
  if ($newBranch) {
    $result = git worktree add $fullPath -b $selectedBranch | Out-String
  } else {
    $result = git worktree add $fullPath $selectedBranch | Out-String
  }

  if ($LASTEXITCODE -eq 0) {
    Set-Location -Path $fullPath
    Write-Host "Created and switched to worktree: $fullPath" -ForegroundColor Green
  } else {
    Write-Host "Failed to create worktree: $result" -ForegroundColor Red
  }
}

function Remove-Worktree {
  $chosenWorktree = Select-WorktreeWithFzf
  if ($chosenWorktree) {
    $chosenWorktreePath = $chosenWorktree.Path -replace '\\', '/'
    $currentPath = (Get-Location).Path -replace '\\', '/'
    if ($chosenWorktreePath -ne $currentPath) {
      git worktree remove $chosenWorktree.Path
      Write-Host "Removed worktree: $($chosenWorktree.Path)" -ForegroundColor Green
    } else {
      Set-Location -Path (Get-Worktrees | Select-Object -First 1).Path
      git worktree remove $chosenWorktree.Path
      Write-Host "Removed worktree and switched to main repo." -ForegroundColor Green
    }
  } else {
    Write-Host "No worktree was selected." -ForegroundColor Yellow
  }
}

$global:WhichGWBindings = @(
  @{
    Key = 'c'
    Desc = '[C]hange Current'
    Action = {
      Switch-Worktree
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  },
  @{
    Key = 's'
    Desc = '[S]how'
    Action = {
      Show-Worktree
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  },
  @{
    Key = 'a'
    Desc = '[A]dd'
    Action = {
      Create-Worktree
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  },
  @{
    Key = 'd'
    Desc = '[D]elete'
    Action = { 
      Remove-Worktree
      [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  }
)
