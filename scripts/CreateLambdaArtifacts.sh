#!/bin/bash

while getopts v: option
do
case "${option}"
in
v) VERSION=${OPTARG};;
esac
done

if [[ -z "${VERSION}" ]]; then
  echo "Please provide a value for the version (-v) parameter. Exiting"
  exit -1
fi

echo "Building/zipping Lambda artifact CreateYouTubeLinksFunction"
go get golang.org/x/sys/unix
GOOS=linux GOARCH=amd64 go build -o ./artifacts/CreateYouTubeLinksFunction/main ./ZeroTube.Functions/CreateYouTubeLinksFunction
zip ./artifacts/CreateYouTubeLinksFunction.zip ./artifacts/CreateYouTubeLinksFunction/main

echo "Building/zipping Lambda artifact GetRandomYouTubeLinkFunction"
GOOS=linux GOARCH=amd64 go build -o ./artifacts/GetRandomYouTubeLinkFunction/main ./ZeroTube.Functions/GetRandomYouTubeLinkFunction
zip ./artifacts/GetRandomYouTubeLinkFunction.zip ./artifacts/GetRandomYouTubeLinkFunction/main

echo "Pushing artifacts to S3 with on '${VERSION}'"
aws s3 cp ./artifacts/CreateYouTubeLinksFunction.zip s3://conway-build-artifacts/zerotube/CreateYouTubeLinksFunction_${VERSION}.zip
aws s3 cp ./artifacts/GetRandomYouTubeLinkFunction.zip s3://conway-build-artifacts/zerotube/GetRandomYouTubeLinkFunction_${VERSION}.zip

echo "Artifact creation complete. Removing locally generated files"
rm -frv ./artifacts/*
