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
    [GitRepositoryInfo] $RepoInfo
  )

  if ($RepoInfo.Type -eq "BitBucketCloud") {
    $encodedSrcBranch = $RepoInfo.Branch
    $encodedDestBranch = "test"
    Write-Host "https://bitbucket.org/$($RepoInfo.Organization)/$($RepoInfo.Repository)/pull-requests/new?source=$encodedSrcBranch&dest=$encodedDestBranch"
  }
}
