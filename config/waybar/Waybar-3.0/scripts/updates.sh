#!/usr/bin/env bash
# Pending package updates (official repositories + AUR) as Waybar JSON.

if ! command -v checkupdates >/dev/null; then
  printf '{"text":"?","tooltip":"Install pacman-contrib to enable checkupdates","class":"error"}\n'
  exit 0
fi

repo=$(checkupdates 2>/dev/null)
aur=$(command -v yay >/dev/null && yay -Qua 2>/dev/null)

n_repo=$(grep -c . <<<"$repo")
n_aur=$(grep -c . <<<"$aur")
total=$((n_repo + n_aur))

tooltip="Repositories: $n_repo   AUR: $n_aur"
[ -n "$repo" ] && tooltip+="\n\n$(head -n 25 <<<"$repo")"
[ -n "$aur" ] && tooltip+="\n\n<b>AUR</b>\n$(head -n 15 <<<"$aur")"
[ "$total" -gt 40 ] && tooltip+="\n…"

class=none
[ "$total" -gt 0 ] && class=pending
[ "$total" -gt 50 ] && class=many

jq -cn --arg t "$total" --arg tt "$tooltip" --arg c "$class" \
  '{text: $t, tooltip: ($tt | gsub("\\\\n"; "\n")), class: $c}'
