#!/bin/bash

while getopts l:b:v: option
do
case "${option}"
in
b) ARTIFACT_BUCKET=${OPTARG};;
v) VERSION=${OPTARG};;
esac
done

echo "Building Solution"
dotnet publish ./ZeroTube.Lambda.PopulateYouTubeLinksFunction/ZeroTube.Lambda.PopulateYouTubeLinksFunction.csproj --configuration Release

echo "Zipping Artifacts"
cd ./ZeroTube.Lambda.PopulateYouTubeLinksFunction/bin/Release/netcoreapp3.1/publish/
zip -r PopulateYouTubeLinksFunction.zip *

echo "Pushing Versioned Artifacts to S3"
aws s3 cp PopulateYouTubeLinksFunction.zip s3://${ARTIFACT_BUCKET}/zerotube/PopulateYouTubeLinksFunction_${VERSION}.zip

echo "Pushing Latest Artifacts to S3"
aws s3 cp PopulateYouTubeLinksFunction.zip s3://${ARTIFACT_BUCKET}/zerotube/PopulateYouTubeLinksFunction_latest.zip