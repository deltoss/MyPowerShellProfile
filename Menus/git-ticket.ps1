class IssueInfo
{
  [string]$Key
  [string]$Url
}

function Get-BaseIssueUrl
{
  $environmentName = "PROJECTMANAGEMENTBASEURL"
  if (-not (Get-Item "env:$environmentName" -ErrorAction SilentlyContinue))
  {
    $value = Read-Host -Prompt "Enter the project management service's base URL for issues"
    Set-Item -Path "env:$environmentName" -Value $value
    [System.Environment]::SetEnvironmentVariable($environmentName, $value, 'User')
    Write-Host "Set $environmentName to: $value" -ForegroundColor Green
  }
  return (Get-Item "env:$environmentName").Value
}

function Get-ProjectKeyPattern
{
  $defaultPattern = '[a-zA-Z][a-zA-Z0-9]{1,9}-[0-9]+'
  $environmentName = "PROJECTMANAGEMENTKEYPATTERN"
  if (-not (Get-Item "env:$environmentName" -ErrorAction SilentlyContinue))
  {
    $value = Read-Host -Prompt "Enter the project key pattern (default: $defaultPattern)"
    if ([string]::IsNullOrWhiteSpace($value))
    {
      $value = $defaultPattern 
    }
    Set-Item -Path "env:$environmentName" -Value $value
    [System.Environment]::SetEnvironmentVariable($environmentName, $value, 'User')
    Write-Host "Set $environmentName to: $value" -ForegroundColor Green
  }
  return (Get-Item "env:$environmentName").Value
}

function Get-IssueInfo
{
  $baseUrl = Get-BaseIssueUrl
  $currentBranch = & git rev-parse --abbrev-ref HEAD

  $pattern = Get-ProjectKeyPattern
  if ($currentBranch -match $pattern)
  {
    $issueInfo = [IssueInfo]::new()
    $issueKey = $Matches[0]
    $issueInfo.Key = $issueKey
    $issueInfo.Url = $baseUrl + $issueKey
    return $issueInfo
  }

  Write-Host "No issue number found from the current branch name"
  return $null
}

function Open-Issue
{
  $issueInfo = Get-IssueInfo
  if ($issueInfo)
  {
    Start-Process (Get-IssueInfo).Url
  }
}
Set-Alias -Name ticket -Value Open-Issue
Set-Alias -Name task -Value Open-Issue
Set-Alias -Name issue -Value Open-Issue