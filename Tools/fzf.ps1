$env:FZF_DEFAULT_COMMAND = 'fd --type f'
$env:FZF_DEFAULT_OPTS = '--height 40% --layout=reverse --border --with-shell "pwsh -NoLogo -NonInteractive -NoProfile -ExecutionPolicy Bypass -Command"'
$env:FZF_CUSTOM_PREVIEW = 'if (Test-Path -Path {} -PathType Container) { eza --tree --level=1 --colour=always --icons=always {} } else { bat --color=always --style=numbers --line-range=:500 {} }'