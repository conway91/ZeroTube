#!/bin/bash

while getopts l:b: option
do
case "${option}"
in
l) LAMBDA_NAME=${OPTARG};;
b) ARTIFACT_BUCKET=${OPTARG};;
esac
done

echo "Clearing Old Aritfacts"
rm -rf ../artefacts/*

echo "Building Solution"
dotnet build ../ZeroTube.sln --configuration Release

echo "Zipping Artifacts"
zip -r -j ../artifacts/${LAMBDA_NAME}.zip ../ZeroTube.Lambda.${LAMBDA_NAME}/bin/Release/netcoreapp3.1/*

echo "Pushing Artifacts to S3"
aws s3 cp ../artifacts/${LAMBDA_NAME}.zip s3://$ARTIFACT_BUCKET