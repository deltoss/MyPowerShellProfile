$script:LeaderKey = '<C-k>'

function Set-LeaderKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$LeaderKey
    )

    $script:LeaderKey = $LeaderKey
}

function Get-LeaderKey {
    return $script:LeaderKey
}

Export-ModuleMember -Function Set-LeaderKey,Get-LeaderKey
