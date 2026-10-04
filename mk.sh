#!/bin/sh

# TODO: allow pinning versions

# $1  slug/id
# $2? game version
# $3? loader
version() {
  versions=""
  if [ -n "$2" ]; then
    versions="&game_versions=[\"$2\"]"
  fi

  loaders=""
  if [ -n "$3" ]; then
    loaders="&loaders=[\"$3\"]"
  fi

  wget -q -O - "https://api.modrinth.com/v2/project/$1/version?include_changelog=false${versions}${loaders}"
}

mod() {
  # look for neoforge 1.21.1
  printf '%-48s %b' "$1" "neoforge 1.21.1 ?" 1>&2
  resp="$(version ${1##*/} 1.21.1 neoforge | jq -r '.[0]')"

  # some list compatibility with 1.21, but not 1.21.1
  if [ "$resp" == "null" ]; then
    printf '\r%-48s %b' "$1" "neoforge 1.21   ?" 1>&2
    resp="$(version ${1##*/} 1.21 neoforge | jq -r '.[0]')"
  fi

  # this mod might be a fabric mod then ...
  if [ "$resp" == "null" ]; then
    printf '\r%-48s %b' "$1" "fabric   1.21.1 ?" 1>&2
    resp="$(version ${1##*/} 1.21.1 fabric | jq -r '.[0]')"
  fi

  if [ "$resp" == "null" ]; then
    printf '%b\n' " not found!" 1>&2
    exit 1
  else
    printf '%b\n' " found!" 1>&2
  fi

  printf '%b' "$resp" \
    | jq -r "{
    url: .files[0].url,
    name: \"${1##*/}\",
    version: .id,
    type: \"mod\"
    }"
}

other() {
  printf '%-48s %b' "$1" "1.21.1 ?" 1>&2
  resp="$(version ${1##*/} 1.21.1 | jq -r '.[0]')"

  # some list compatibility with 1.21, but not 1.21.1
  if [ "$resp" == "null" ]; then
    printf '\r%-48s %b' "$1" "1.21   ?" 1>&2
    resp="$(version ${1##*/} 1.21 | jq -r '.[0]')"
  fi

  if [ "$resp" == "null" ]; then
    printf '%b\n' " not found!" 1>&2
    exit 1
  else
    printf '%b\n' " found!" 1>&2
  fi

  printf '%b' "$resp" \
    | jq -r "{
    url: .files[0].url,
    name: \"${1##*/}\",
    version: .id,
    type: \"${1%%/*}\"
    }"
}

{
  cat content.json
  # fetch latest from content from modrinth API
  while read -r line; do
    case "$line" in
      "#"*)  continue;;
      mod/*) mod   "$line";;
      *)     other "$line";;
    esac
  done < content.desc
} \
  | jq -s -r '{
    sync_version: 3,
    sync: .
  }' > sync.json

