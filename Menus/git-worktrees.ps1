function Get-MainRepoFolder
{
  # Get the common .git directory
  $gitCommonDir = git rev-parse --path-format=absolute --git-common-dir

  # Get the main worktree from that
  return Split-Path $gitCommonDir -Parent
}

function Get-WorktreesFolder
{
  $worktreeFolder = "$(Get-MainRepoFolder).worktrees/"

  Write-Host "Worktree folder: $worktreeFolder" -ForegroundColor Green
  return $worktreeFolder
}

function Get-Worktrees
{
  $output = git worktree list --porcelain | Out-String
  $entries = $output -split '(\r?\n){2}' | Where-Object { $_.Trim() }

  if ($entries.Count -eq 0)
  {
    Write-Host "No worktrees found."
    return @()
  }

  $mainRepoPath = Get-MainRepoFolder
  $parentPath = if (-not [string]::IsNullOrEmpty($mainRepoPath))
  {
    Split-Path -Parent $mainRepoPath
  } else
  {
    $null
  }

  $entries | ForEach-Object {
    $lines = $_ -split '\r?\n' | Where-Object { $_ }
    $fullPath = $lines[0] -replace '^worktree ', ''

    if (-not [string]::IsNullOrEmpty($parentPath) -and -not [string]::IsNullOrEmpty($fullPath))
    {
      try
      {
        $relativePath = [System.IO.Path]::GetRelativePath($parentPath, $fullPath)
      } catch
      {
        Write-Host "Failed to get relative path: $_"
        $relativePath = $fullPath
      }
    } else
    {
      $relativePath = $fullPath
    }

    [PSCustomObject]@{
      Path = $fullPath
      RelativePath = $relativePath
      Commit = $lines[1] -replace '^HEAD ', ''
      CommitShort = ($lines[1] -replace '^HEAD ', '').Substring(0, 7)
      Branch = if ($lines[2] -match '^branch ')
      {
        $lines[2] -replace '^branch refs/heads/', ''
      } else
      {
        '(detached)'
      }
    }
  }
}

function Select-WorktreeWithFzf
{
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

function Show-Worktree
{
  $chosenWorktree = Select-WorktreeWithFzf
  if ($chosenWorktree)
  {
    Write-Host "Selected Worktree: $($chosenWorktree | Format-List | Out-String)" -ForegroundColor Green
  } else
  {
    Write-Host "No worktree was selected."
  }
}

function Switch-Worktree
{
  $chosenWorktree = Select-WorktreeWithFzf
  if ($chosenWorktree)
  {
    Set-Location -Path $chosenWorktree.Path
    Write-Host "Switched to worktree: $($chosenWorktree.Path)" -ForegroundColor Green
  } else
  {
    Write-Host "No worktree was selected." -ForegroundColor Yellow
  }
}

function Create-Worktree
{
  try
  {
    $worktreePath = Get-WorktreesFolder
    if (-not $worktreePath)
    {
      throw "Failed to get worktrees folder path"
    }

    $interaction = Select-GitBranch
    if (-not $interaction)
    {
      Write-Host "No branch was selected." -ForegroundColor Yellow
      return
    }

    $selectedBranch = $null
    $newBranch = $interaction.Query -and -not $interaction.Branch
    if ($newBranch)
    {
      $selectedBranch = $interaction.Query
      Write-Host "Will create new branch: $selectedBranch" -ForegroundColor Green
    } else
    {
      $selectedBranch = $interaction.Branch -replace "^origin/", ""
    }

    if ([string]::IsNullOrWhiteSpace($selectedBranch))
    {
      throw "Selected branch name is empty or invalid"
    }

    $relativePath = Read-Host -Prompt "Enter the new worktree directory name (default: $selectedBranch)"
    if (-not $relativePath)
    {
      $relativePath = $selectedBranch
    }

    # Create worktree parent directory if it doesn't exist
    if (!(Test-Path -Path $worktreePath))
    {
      try
      {
        New-Item -ItemType Directory -Path $worktreePath -ErrorAction Stop | Out-Null
        Write-Host "Created worktree folder at: $worktreePath" -ForegroundColor Green
      } catch
      {
        throw "Failed to create worktree directory at '$worktreePath': $($_.Exception.Message)"
      }
    }

    $fullPath = Join-Path $worktreePath $relativePath

    # Check if worktree path already exists
    if (Test-Path -Path $fullPath)
    {
      throw "Worktree path already exists: $fullPath"
    }

    Write-Host "Creating worktree at: $fullPath" -ForegroundColor Green

    # Execute git worktree add with error handling
    $result = $null
    try
    {
      if ($newBranch)
      {
        $result = git worktree add $fullPath -b $selectedBranch 2>&1
      } else
      {
        $result = git worktree add $fullPath $selectedBranch 2>&1
      }

      if ($LASTEXITCODE -ne 0)
      {
        throw "Git worktree command failed with exit code $LASTEXITCODE. Output: $result"
      }

      # Try to switch to the new worktree
      try
      {
        Set-Location -Path $fullPath -ErrorAction Stop
        Write-Host "Created and switched to worktree: $fullPath" -ForegroundColor Green
      } catch
      {
        Write-Warning "Worktree created but failed to switch location: $($_.Exception.Message)"
        Write-Host "Worktree created at: $fullPath" -ForegroundColor Yellow
      }
    } catch
    {
      Write-Host "Failed to create worktree: $($_.Exception.Message)" -ForegroundColor Red

      # Cleanup: Try to remove partially created worktree
      if (Test-Path -Path $fullPath)
      {
        try
        {
          git worktree remove $fullPath --force 2>&1 | Out-Null
          Write-Host "Cleaned up partial worktree at: $fullPath" -ForegroundColor Yellow
        } catch
        {
          Write-Warning "Could not clean up partial worktree at: $fullPath"
        }
      }
      throw
    }
  } catch
  {
    Write-Error "Create-Worktree failed: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    return
  }
}

function Remove-Worktree
{
  $chosenWorktree = Select-WorktreeWithFzf
  if ($chosenWorktree)
  {
    $chosenWorktreePath = $chosenWorktree.Path -replace '\\', '/'
    $currentPath = (Get-Location).Path -replace '\\', '/'
    if ($chosenWorktreePath -ne $currentPath)
    {
      git worktree remove $chosenWorktree.Path
      Write-Host "Removed worktree: $($chosenWorktree.Path)" -ForegroundColor Green
    } else
    {
      Set-Location -Path (Get-Worktrees | Select-Object -First 1).Path
      git worktree remove $chosenWorktree.Path
      Write-Host "Removed worktree and switched to main repo." -ForegroundColor Green
    }
  } else
  {
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