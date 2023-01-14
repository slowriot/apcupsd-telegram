#!/bin/bash

string="$1"
if [ "$string" = "" ]; then
  string=$(cat)
fi

if [ "$string" = "" ]; then
  exit
fi

perl -MURI::Escape -e 'print uri_escape($ARGV[0]);' "$string"
