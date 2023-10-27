package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"google.golang.org/api/option"
	"google.golang.org/api/youtube/v3"
)

type YouTubeModel struct {
	Id        string
	VideoId   string
	ViewCount string
}

func main() {
	lambda.Start(HandleRequest)
}

func HandleRequest(ctx context.Context) {
	dynamoClient := dynamodb.New(session.Must(session.NewSession()))
	youTubeService := getYouTubeService()
	youTubeModels := getAllDynamoEntriesByVideoId(dynamoClient)
	deleteYouTubeVideoIdsByViews(youTubeModels, youTubeService, dynamoClient)
}

func getAllDynamoEntriesByVideoId(dynamoClient *dynamodb.DynamoDB) map[string]YouTubeModel {
	tableName := os.Getenv("DYNAMO_TABLE_NAME")
	log.Printf("Getting all entries from dynamo table : '%s'", tableName)

	result, err := dynamoClient.Scan(&dynamodb.ScanInput{
		TableName: aws.String(tableName),
	})
	HandleError(err)

	youtubeModels := make(map[string]YouTubeModel)
	for _, item := range result.Items {
		youtubeModel := YouTubeModel{}

		err = dynamodbattribute.UnmarshalMap(item, &youtubeModel)
		HandleError(err)

		youtubeModels[youtubeModel.VideoId] = youtubeModel
	}

	log.Printf("Total entries : '%v'", len(youtubeModels))

	return youtubeModels
}

func deleteYouTubeVideoIdsByViews(youTubeModels map[string]YouTubeModel, youTubeService *youtube.Service, dynamoClient *dynamodb.DynamoDB) {
	log.Printf("Deleting videos with a view count higher than '%s'", os.Getenv("MAXIMUM_VIEW_COUNT"))

	var videoIds []string
	for _, entry := range youTubeModels {
		videoIds = append(videoIds, entry.VideoId)
	}

	formattedVideoIds := strings.Join(videoIds[:], ",")
	maxViewCount, err := strconv.ParseUint(os.Getenv("MAXIMUM_VIEW_COUNT"), 10, 64)
	HandleError(err)

	serviceVideoCall := youTubeService.Videos.
		List([]string{"statistics"}).
		Id(formattedVideoIds)

	serviceVideoCallResponse, err := serviceVideoCall.Do()
	HandleError(err)

	log.Printf("YouTube API returned '%v' videos", len(serviceVideoCallResponse.Items))

	var dynamoIdsToDelete []string
	for _, item := range serviceVideoCallResponse.Items {
		if item.Statistics.ViewCount >= maxViewCount {
			log.Printf("Video with id '%s' and view count '%b' to be deleted", item.Id, maxViewCount)
			currentEntry := youTubeModels[item.Id]
			dynamoIdsToDelete = append(dynamoIdsToDelete, currentEntry.Id)
		}
	}

	if len(dynamoIdsToDelete) > 0 {
		deleteDynamoEntries(dynamoClient, dynamoIdsToDelete)
	} else {
		log.Print("No models found that need deleted")
	}
}

func deleteDynamoEntries(dynamoClient *dynamodb.DynamoDB, modelIds []string) {
	tableName := os.Getenv("DYNAMO_TABLE_NAME")
	log.Printf("Deleting '%b' Videos from table '%s'", len(modelIds), tableName)

	for _, modelId := range modelIds {
		_, err := dynamoClient.DeleteItem(&dynamodb.DeleteItemInput{
			Key: map[string]*dynamodb.AttributeValue{
				"Id": {
					N: aws.String(modelId),
				},
			},
			TableName: aws.String(tableName),
		})
		HandleError(err)
	}
}

func getYouTubeService() *youtube.Service {
	log.Print("Getting YouTube service")

	apiKey := os.Getenv("YOUTUBE_API_TOKEN")

	service, err := youtube.NewService(context.Background(), option.WithAPIKey(apiKey))
	HandleError(err)

	return service
}

func HandleError(err error) {
	if err != nil {
		panic(fmt.Sprintf("Error encountered. Log : %v", err))
	}
}
