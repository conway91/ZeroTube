#!/bin/bash

while getopts l:b:v: option
do
case "${option}"
in
b) ARTIFACT_BUCKET=${OPTARG};;
v) VERSION=${OPTARG};;
esac
done

echo "Building/zipping Lambda CreateYouTubeLinksFunction"
GOOS=linux GOARCH=amd64 go build -o ./artifacts/CreateYouTubeLinksFunction/main -i ./ZeroTube.Functions/CreateYouTubeLinksFunction
zip ./artifacts/CreateYouTubeLinksFunction.zip ./artifacts/CreateYouTubeLinksFunction/main