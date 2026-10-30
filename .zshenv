export PATH="$HOME/.local/bin:$PATH"

# Homebrew phải đứng trước /usr/bin, kể cả trong shell KHÔNG-login (script, IDE, cron, agent).
# `eval "$(brew shellenv)"` chỉ chạy ở ~/.zprofile nên login shell đã đúng; guard này bù cho phần còn lại.
if [[ -d /opt/homebrew/bin ]]; then
  if (( ${path[(Ie)/opt/homebrew/bin]} )); then
    _hb_i=${path[(i)/opt/homebrew/bin]}
    _usr_i=${path[(i)/usr/bin]}
    if (( _usr_i && _usr_i < _hb_i )); then
      path=(/opt/homebrew/bin ${path:#/opt/homebrew/bin})
    fi
  else
    path=(/opt/homebrew/bin $path)
  fi
  (( ${path[(Ie)/opt/homebrew/sbin]} )) || path+=(/opt/homebrew/sbin)
  export PATH
  unset _hb_i _usr_i
fi
