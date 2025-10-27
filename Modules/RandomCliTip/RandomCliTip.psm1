$favoriteCliUri = "https://gist.githubusercontent.com/deltoss/bfe4f567be2f94d217b168058823e372/raw/FavoriteCLICheatsheet.json"

function Get-CachedJsonFromUrl {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $false)]
        [string]$CacheFilePath = "$env:TEMP\cached_data.json",

        [Parameter(Mandatory = $false)]
        [int]$CacheExpirationHours = 24
    )

    # Create cache metadata file path
    $metadataPath = "$CacheFilePath.metadata"

    # Check if cache file exists and is not expired
    $useCache = $false
    if (Test-Path $CacheFilePath -PathType Leaf) {
        if (Test-Path $metadataPath -PathType Leaf) {
            try {
                $metadata = Get-Content $metadataPath | ConvertFrom-Json

                if ($metadata.timestamp) {
                    # No need to parse - ConvertFrom-Json already converted to DateTime
                    $cacheTime = $metadata.timestamp
                    $expirationTime = $cacheTime.AddHours($CacheExpirationHours)

                    if ([DateTime]::Now -lt $expirationTime) {
                        $useCache = $true
                        Write-Verbose "Using cached data from $CacheFilePath (expires on $expirationTime)"
                    }
                    else {
                        Write-Verbose "Cache expired. Fetching fresh data."
                    }
                }
            }
            catch {
                Write-Warning "Error reading cache metadata: $_"
                # Continue to fetch fresh data
            }
        }
    }

    # Use cached data or fetch fresh data
    if ($useCache) {
        try {
            $data = Get-Content $CacheFilePath -Raw | ConvertFrom-Json
        }
        catch {
            Write-Warning "Error reading cache data: $_"
            $useCache = $false # Force fetching fresh data
        }
    }

    if (-not $useCache) {
        try {
            # Fetch data from URL - Invoke-RestMethod automatically converts JSON to objects
            $data = Invoke-RestMethod -Uri $Url -Method Get

            # Save data to cache file
            $data | ConvertTo-Json -Depth 100 | Out-File $CacheFilePath -Force

            # Save metadata - PowerShell will automatically convert DateTime to JSON
            @{
                timestamp = [DateTime]::Now
                url = $Url
            } | ConvertTo-Json | Out-File $metadataPath -Force

            Write-Verbose "Fresh data fetched and cached successfully."
        }
        catch {
            # If fetch fails but cache exists, use it regardless of expiration
            if (Test-Path $CacheFilePath -PathType Leaf) {
                Write-Warning "Failed to fetch fresh data. Using expired cache as fallback."
                try {
                    $data = Get-Content $CacheFilePath -Raw | ConvertFrom-Json
                }
                catch {
                    throw "Failed to fetch data and couldn't read cache: $_"
                }
            }
            else {
                throw "Failed to fetch data and no cache available: $_"
            }
        }
    }

    return $data
}

function Get-RandomFavoriteCli {
    try {
        # Fetch the JSON data from the gist
        $response = Get-CachedJsonFromUrl -Url $favoriteCliUri -CacheFilePath "$env:TEMP\FavoriteCLICheatsheet.json" -Verbose

        $randomItem = $response.clitools | Get-Random

        Write-Host "`n🔧 Random CLI Tool:" -ForegroundColor Cyan
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
        Write-Host "Name:        " -NoNewline -ForegroundColor Yellow
        Write-Host $randomItem.name
        Write-Host "Command:     " -NoNewline -ForegroundColor Yellow
        Write-Host $randomItem.command -ForegroundColor Green
        Write-Host "Description: " -NoNewline -ForegroundColor Yellow
        Write-Host $randomItem.description
        if ($randomItem.tags) {
            Write-Host "Tags:        " -NoNewline -ForegroundColor Yellow
            Write-Host ($randomItem.tags -join ", ") -ForegroundColor Magenta
        }
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
        Write-Host "`n🔍 Running tldr for: $($randomItem.command)" -ForegroundColor Cyan
        Write-Host ""

        # Run tldr for the selected tool
        tldr --quiet $randomItem.command
    } catch {
        Write-Error "Failed to fetch data or run tldr: $($_.Exception.Message)"
        Write-Host "Make sure you have 'tldr' installed and accessible in your PATH" -ForegroundColor Yellow
    }
}

Get-RandomFavoriteCli

function Search-Tldr {
    $selected = tldr --list | fzf --prompt="🔧 Select a CLI tool > " --height=20 --border --preview-window=wrap --preview="echo {}" --header="Use ↑↓ to navigate, Enter to select, Esc to cancel"

    & tldr $selected
}

function Search-FavoriteCliTools {
    try {
        # Fetch the JSON data from the gist
        $response = Get-CachedJsonFromUrl -Url $favoriteCliUri -CacheFilePath "$env:TEMP\FavoriteCLICheatsheet.json" -Verbose

        # Format CLI tools for fzf
        $items = $response.clitools | ForEach-Object {
            if ($_.name -ceq $_.command) {
                "$($_.command) | $($_.description)"
            } else {
                "$($_.name) | $($_.command) | $($_.description)"
            }
        }

        # Use fzf to select a tool
        $selected = $items | fzf --prompt="🔧 Select a CLI tool > " --height=20 --border --preview-window=wrap --preview="echo {}" --header="Use ↑↓ to navigate, Enter to select, Esc to cancel"

        if ($selected) {
            # Parse the selected item
            $parts = $selected -split " \| "
            if ($parts.Count -eq 2) {
                $name = $parts[0]
                $command = $parts[0]  # Same as name
                $description = $parts[1]
            } else {
                $name = $parts[0]
                $command = $parts[1]
                $description = $parts[2]
            }

            Write-Host "`n🔧 Selected CLI Tool:" -ForegroundColor Cyan
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
            Write-Host "Name:        " -NoNewline -ForegroundColor Yellow
            Write-Host $name
            Write-Host "Command:     " -NoNewline -ForegroundColor Yellow
            Write-Host $command -ForegroundColor Green
            Write-Host "Description: " -NoNewline -ForegroundColor Yellow
            Write-Host $description
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
            Write-Host "`n🔍 Running tldr for: $command" -ForegroundColor Cyan
            Write-Host ""

            # Run tldr for the selected tool
            tldr --quiet $command
        } else {
            Write-Host "No selection made." -ForegroundColor Yellow
        }

    } catch {
        Write-Error "Failed to fetch data or run fzf: $($_.Exception.Message)"
        Write-Host "Make sure you have 'fzf' installed and accessible in your PATH" -ForegroundColor Yellow
    }
}

$global:WhichPBindings = @(
  @{
    Key = 'r'
    Desc = 'Get [R]andom Favorite CLI Tip'
    Action = {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert('Get-RandomFavoriteCli')
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  },
  @{
    Key = 't'
    Desc = 'Search Favorite CLI [T]ools'
    Action = {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert('Search-FavoriteCliTools')
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  },
  @{
    Key = 'T'
    Desc = 'Search [T]ldr'
    Action = {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert('Search-Tldr')
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
  }
)

Set-PSReadLineKeyHandler -Key Ctrl+p -ScriptBlock {
  Show-WhichMenu -Bindings $global:WhichPBindings -Title 'Help [P]ages'
}

Export-ModuleMember -Function Get-RandomFavoriteCli,Search-Tldr,Search-FavoriteCliTools
