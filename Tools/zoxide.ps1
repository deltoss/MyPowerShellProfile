$env:ZOXIDE_FZF_CUSTOM_PREVIEW = 'eza --tree --level=1 --colour=always --icons=always ({} -replace "[^\t]+\t", "")'
$env:_ZO_FZF_OPTS = $env:FZF_DEFAULT_OPTS + " --preview='$env:ZOXIDE_FZF_CUSTOM_PREVIEW'"

Invoke-Expression (& { (zoxide init powershell | Out-String) })
