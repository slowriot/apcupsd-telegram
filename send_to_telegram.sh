#!/bin/bash
# Simple one-way generic announcer to telegram

scriptdir=$(dirname "${BASH_SOURCE[0]}")

token="$(cat telegram_bot_token.txt)"

endpoint="https://api.telegram.org"
api="$endpoint/bot$token"

update_id_file="$scriptdir/telegram_last_update.txt"
urlencode="$scriptdir/urlencode.sh"

target_chat_ids="-1001816900406"

disablepreview=false
if [ "$2" = "--nopreview" ]; then
  disablepreview=true
fi

function send_raw() {
  # 1 = raw command to send
  #echo "DEBUG: running: wget $api/$1" >&2
  wget --timeout=30 -q "$api/$1" -O - | jq .
}
function send_message() {
  # 1 = chat id
  # 2 = text
  text=$("$urlencode" <<< "$2")
  if $disablepreview; then
    send_raw "sendmessage?chat_id=$1&text=$text&parse_mode=HTML&disable_web_page_preview=true"
  else
    send_raw "sendmessage?chat_id=$1&text=$text&parse_mode=HTML"
  fi
}
function send_reply() {
  # 1 = chat id
  # 2 = message id
  # 3 = text
  text=$("$urlencode" <<< "$3")
  send_raw "sendmessage?chat_id=$1&reply_to_message_id=$2&text=$text"
}
function send_busy() {
  # 1 = chat id
  send_raw "sendChatAction?chat_id=$1&action=typing"
}
function send_to_all() {
  # 1 = text
  for chat_id in $target_chat_ids; do
    send_busy "$chat_id"
  done
  for chat_id in $target_chat_ids; do
    send_message "$chat_id" "$1"
  done
}

# first reply with a busy message, documentation of message types: https://core.telegram.org/bots/api#sendchataction
#send_busy "$chat_id"
#send_message "$chat_id" "Testing"

send_to_all "$1" >/dev/null

update_id_last=$(cat "$update_id_file" 2>/dev/null)
if [ -z "$update_id_last" ]; then
  updates=$(send_raw "getUpdates")
  echo "All updates so far:"
else
  updates=$(send_raw "getUpdates?offset=$((update_id_last + 1))")
  echo "Updates since $update_id_last:"
fi
# pass again through jq to re-colourise
echo "$updates" | jq .
update_id=$(jq '.result[0].update_id' <<< "$updates")
echo "$update_id" > "$update_id_file"
