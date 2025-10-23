class GitRepositoryInfo {
  [string]$Organization
  [string]$Repository
  [string]$Branch
  [string]$Url
  [string]$Type
}

function Get-RepositoryInformation {

  # Get the remote URL
  $remoteUrl = & git config --get remote.origin.url
  $branch = & git branch --show-current

  # GitHub URLs
  if ($remoteUrl -match "github\.com[:\/]([^\/:]+)\/([^.]+)\.git") {
    $repo = [GitRepositoryInfo]::new()
    $repo.Organization = $matches[1]
    $repo.Repository = $matches[2]
    $repo.Branch = $branch
    $repo.Url = $remoteUrl
    $repo.Type = "GitHub"
    return $repo
  }

  # Bitbucket Cloud URLs
  if ($remoteUrl -match "bitbucket\.org[:\/]([^\/:]+)\/([^.]+)\.git") {
    $repo = [GitRepositoryInfo]::new()
    $repo.Organization = $matches[1]
    $repo.Repository = $matches[2]
    $repo.Branch = $branch
    $repo.Url = $remoteUrl
    $repo.Type = "BitBucketCloud"
    return $repo
  }

  return $null;
}

function Get-PullRequestUrl {
  param (
    [string] $DestBranch = 'develop',
    [GitRepositoryInfo] $RepoInfo = $null
  )

  if ($RepoInfo -eq $null) {
    $RepoInfo = Get-RepositoryInformation
  }

  $srcBranch = $RepoInfo.Branch

  if ($RepoInfo.Type -eq "GitHub") {
    return "https://github.com/$($RepoInfo.Organization)/$($RepoInfo.Repository)/compare/$($srcBranch)...$($DestBranch)?expand=1"
  } elseif ($RepoInfo.Type -eq "BitBucketCloud") {
    return "https://bitbucket.org/$($RepoInfo.Organization)/$($RepoInfo.Repository)/pull-requests/new?source=$($srcBranch)&dest=$($DestBranch)"
  }
  return $null
}

function Open-PullRequest {
  param (
    [string] $DestBranch = 'develop'
  )

  Start-Process (Get-PullRequestUrl $DestBranch)
}
Set-Alias -Name pr -Value Open-PullRequest
