#!/bin/bash

API_KEY=$1

if [ -z "$API_KEY" ]; then
    echo "Usage: $0 <API Key>"
    exit 1
fi

API_VERSION=v1.4
API_BASE_URL=https://www.wanikani.com/api/$API_VERSION/user/
CURL="/usr/bin/curl --progress-bar"

#$CURL --url $API_BASE_URL/$API_KEY/study-queue -o "SQPTStudyQueue.json"
$CURL \
    --url $API_BASE_URL/$API_KEY/radicals -o "SQPTRadicals.json" \
    --url $API_BASE_URL/$API_KEY/kanji -o "SQPTKanji.json" \
    --url $API_BASE_URL/$API_KEY/vocabulary -o "SQPTVocab.json"
