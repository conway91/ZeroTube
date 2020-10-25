#!/bin/bash

while getopts a:s:r: option
do
case "${option}"
in
a) ARTIFACT_BUCKET=${OPTARG};;
s) STATE_BUCKET=${OPTARG};;
r) REGION=${OPTARG};;
esac
done

echo "Artifact Bucket : $ARTIFACT_BUCKET";
echo "State Bucket : $STATE_BUCKET";
echo "Bucket Region : $REGION";

echo "Create Artifact Bucket"
aws s3api create-bucket --bucket $ARTIFACT_BUCKET --region $REGION --create-bucket-configuration LocationConstraint=$REGION

echo "Create State Bucket"
aws s3api create-bucket --bucket $STATE_BUCKET --region $REGION --create-bucket-configuration LocationConstraint=$REGION
