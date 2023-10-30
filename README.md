# ZeroTube
<a href="https://www.youtube.com" target="_blank">YouTube</a> is a free video-sharing website that makes it easy to watch online videos. You can even create and upload your videos to share with others. It also promotes and recommends user-uploaded videos based on popularity, views, and relevance. But have you ever wondered about the videos that have no views? Videos that no one else in the world has viewed yet? YouTube does not give you an option to filter videos based on views so this is not an option using the main website or API.


<a href="https://zerotube.net" target="_blank">ZeroTube.net</a> is an open-source website that allows users to get a randomly selected video that has zero (or as close to zero as possible) views. Each refresh of the page loads a new video. The purpose of this passion project is to explore the opposite side of YouTube. The part that no one, quite literally, has seen before.


The website functions by using search terms that are commonly used by videos that have fewer views and filters out the ones with views. It then stores these video IDs in a database ready to be loaded by the frontend. An example of these search terms is video format extensions (e.g. `.avi`, `.mp4`, `.mov`) which are then left in either the video title or description, a common mistake made by users which results in their videos getting fewer views


## Tech Stack
* Go
* React
* AWS
* Terraform (v0.13)
* GitHub Action Pipelines


The main website frontend is React and is hosted as an AWS S3 static site with the backend being formed by three AWS Lambdas. The data layer is a DyanmoDB table. The AWS Cloud infrastructure is created through IaC (Terraform) and deployed via GitHub Actions.


## Lambdas
The backend of the application consists of three AWS Lambdas written in GoLang. One to populate the database with YouTube links to videos with zero views, one to periodically clean the links in the database that are no longer active or have gone over the viewed threshold, and finally one that gets a random entry back from the database which is used by a public endpoint hosted on AWS API Gateway.


### CreateYouTubeLinksFunction
The function of this Lambda is to populate the DyanmoDB database with video IDs


Environmental variables:
* `SEARCH_TERMS` - The variable used to filter the YouTube videos retrieved from the YouTube API.
* `DYNAMO_TABLE_NAME` - The variable for the DyanmoDB table name that is used to store the video IDs.
* `YOUTUBE_API_TOKEN` - The variable used to store the API token used to connect to YouTube's API.
* `MAXIMUM_VIEW_COUNT` - The variable used to store the value that we use to filter out more viewed content. If this value is set to 5 then the Lambda will save videos with 0 - 5 views.


### CleanupYouTubeLinksFunction
The function of this Lambda is to clean up video IDs from the DynamoDB table that are no longer active or have exceeded the `MAXIMUM_VIEW_COUNT` variable


Environmental variables:
* `DYNAMO_TABLE_NAME` - The variable for the DyanmoDB table name that is used to store the video IDs.
* `YOUTUBE_API_TOKEN` - The variable used to store the API token used to connect to YouTube's API.
* `MAXIMUM_VIEW_COUNT` - The variable used to store the value that we use to filter out more viewed content. If this value is set to 5 then the Lambda will save videos with 0 - 5 views.


### GetRandomYouTubeLinkFunction
The function of this Lambda is to allow the AWS API Gateway GET request to get a random video back from the DynamoDB database.


Returned JSON Response example:
```
{
"Id": "6116f581-3f88-44b1-aa4e-ebad5adff601",
"VideoId": "r0YdsxqJIQw",
"ViewCount": "2"
}
```


Environmental variables:
* `DYNAMO_TABLE_NAME` - The variable for the DyanmoDB table name that is used to store the video IDs.
