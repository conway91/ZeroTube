#!/bin/bash

while getopts l:b:v: option
do
case "${option}"
in
l) LAMBDA_NAME=${OPTARG};;
b) ARTIFACT_BUCKET=${OPTARG};;
v) VERSION=${OPTARG};;
esac
done

echo "Clearing Old Aritfacts"
rm -rf ./artifacts/*

echo "Building Solution"
dotnet publish ./ZeroTube.Lambda.${LAMBDA_NAME}/ZeroTube.Lambda.${LAMBDA_NAME}.csproj --configuration Release

echo "Zipping Artifacts"
cd ./ZeroTube.Lambda.${LAMBDA_NAME}/bin/Release/netcoreapp3.1/publish/
zip -r ${LAMBDA_NAME}.zip *

echo "Pushing Versioned Artifacts to S3"
aws s3 cp ${LAMBDA_NAME}.zip s3://${ARTIFACT_BUCKET}/zerotube/${LAMBDA_NAME}_${VERSION}.zip

echo "Pushing Latest Artifacts to S3"
aws s3 cp ${LAMBDA_NAME}.zip s3://${ARTIFACT_BUCKET}/zerotube/${LAMBDA_NAME}_latest.zip