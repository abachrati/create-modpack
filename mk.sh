#!/bin/sh

# TODO: allow pinning versions

OVERRIDES_URL="https://raw.githubusercontent.com/abachrati/create-modpack/refs/heads/main/overrides.zip"
OVERRIDES_VERSION="0"

# $1 slug/id
# $2 game version
# $3 loader
version() {
  wget -q -O - "https://api.modrinth.com/v2/project/$1/version?game_versions=[\"$2\"]&loaders=[\"$3\"]&include_changelog=false"
}

mod() {
  # look for neoforge 1.21.1
  printf '%-32s %b' "$1" "neoforge 1.21.1 ?" 1>&2
  resp="$(version $1 1.21.1 neoforge | jq -r '.[0]')"

  # some neoforge mods are compatible with 1.21.1, but only list 1.21
  if [ "$resp" == "null" ]; then
    printf '\r%-32s %b' "$1" "neoforge 1.21 ?" 1>&2
    resp="$(version $1 1.21 neoforge | jq -r '.[0]')"
  fi

  # this mod might be a fabric mod then ...
  if [ "$resp" == "null" ]; then
    printf '\r%-32s %b' "$1" "fabric   1.21.1 ?" 1>&2
    resp="$(version $1 1.21.1 fabric | jq -r '.[0]')"
  fi

  printf '%b\n' " found!" 1>&2

  printf '%b' "$resp" \
    | jq -r "{
    url: .files[0].url,
    name: \"$1\",
    version: .id,
    type: \"mod\"
    }"
}

{
  # add overrides artifact
  cat << EOF
{
  "url": "$OVERRIDES_URL",
  "name": "overrides",
  "version": "$OVERRIDES_VERSION",
  "type": "packed",
  "directory": "."
}
EOF

  # fetch latest from content from modrinth API
  while read -r line; do
    mod "$line"
  done < "$1"
} \
  | jq -s -r '{
    sync_version: 3,
    sync: .
  }' > sync.json

