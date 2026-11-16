# shellcheck shell=bash
# shellcheck disable=SC2207

_bluetooth_revamped() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  case "${prev}" in
  --theme)
    COMPREPLY=($(compgen -W "kodougu catppuccin-mocha catppuccin-latte dracula nord gruvbox tokyo-night mono" -- "${cur}"))
    return
    ;;
  status)
    COMPREPLY=($(compgen -W "device icon count min" -- "${cur}"))
    return
    ;;
  --interval | --format | --separator | --icon)
    COMPREPLY=()
    return
    ;;
  *) ;;
  esac

  COMPREPLY=($(compgen -W "status list refresh doctor version help --interval --format --separator --icon --json --theme" -- "${cur}"))
}

complete -F _bluetooth_revamped bluetooth-revamped
