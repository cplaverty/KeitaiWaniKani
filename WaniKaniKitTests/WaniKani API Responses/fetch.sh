#!/bin/bash

API_KEY=$1

if [ -z "$API_KEY" ]; then
    echo "Usage: $0 <API Key>"
    exit 1
fi

API_VERSION=v1.4
API_BASE_URL=https://www.wanikani.com/api/$API_VERSION/user/
CURL="/usr/bin/curl --progress-bar"

#$CURL --url $API_BASE_URL/jfsaisafjskjfsfsfs/study-queue -o "Bad API Key.json"

#$CURL \
#    --url $API_BASE_URL/$API_KEY/study-queue -o "Study Queue Success.json" \
#    --url $API_BASE_URL/$API_KEY/level-progression -o "Level Progression.json" \
#    --url $API_BASE_URL/$API_KEY/srs-distribution -o "SRS Distribution.json" \
#    --url $API_BASE_URL/$API_KEY/radicals/1 -o "Radicals Level 1.json" \
#    --url $API_BASE_URL/$API_KEY/kanji/2 -o "Kanji Level 2.json" \
#    --url $API_BASE_URL/$API_KEY/vocabulary/1 -o "Vocab Level 1.json"

$CURL \
    --url $API_BASE_URL/$API_KEY/radicals/1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20 -o "Radicals Levels 1-20.json" \
    --url $API_BASE_URL/$API_KEY/kanji/1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20 -o "Kanji Levels 1-20.json" \
    --url $API_BASE_URL/$API_KEY/vocabulary/1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20 -o "Vocab Levels 1-20.json"
