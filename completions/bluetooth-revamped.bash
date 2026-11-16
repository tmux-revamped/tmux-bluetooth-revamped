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
  power)
    COMPREPLY=($(compgen -W "on off toggle" -- "${cur}"))
    return
    ;;
  --icons | --notify)
    COMPREPLY=($(compgen -W "0 1" -- "${cur}"))
    return
    ;;
  --interval | --format | --separator | --icon | --low | --popup-key | connect | disconnect)
    COMPREPLY=()
    return
    ;;
  *) ;;
  esac

  COMPREPLY=($(compgen -W "status list refresh connect disconnect power popup doctor version help --interval --format --separator --icon --icons --notify --low --popup-key --json --theme" -- "${cur}"))
}

complete -F _bluetooth_revamped bluetooth-revamped
