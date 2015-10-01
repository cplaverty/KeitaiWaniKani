#!/bin/bash

API_KEY=**ENTER API KEY HERE**

API_VERSION=v1.4
API_BASE_URL=https://www.wanikani.com/api/$API_VERSION/user/
CURL="/usr/bin/curl --progress-bar"

#$CURL $API_BASE_URL/$API_KEY/study-queue -o "SQPTStudyQueue.json"
$CURL $API_BASE_URL/$API_KEY/radicals -o "SQPTRadicals.json"
$CURL $API_BASE_URL/$API_KEY/kanji -o "SQPTKanji.json"
$CURL $API_BASE_URL/$API_KEY/vocabulary -o "SQPTVocab.json"
