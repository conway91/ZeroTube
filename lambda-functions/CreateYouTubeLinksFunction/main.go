package main

import (
	"context"
	"fmt"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"github.com/google/uuid"
	"google.golang.org/api/option"
	"google.golang.org/api/youtube/v3"
	"log"
	"os"
	"strconv"
	"strings"
	"time"
)

type YouTubeModel struct {
	Id string
	VideoId string
	ViewCount string
}

func main() {
	lambda.Start(HandleRequest)
}

func HandleRequest(ctx context.Context) {
	youTubeService := getYouTubeService()
	queryTerms := strings.Split(os.Getenv("SEARCH_TERMS"), ",")
	dynamoClient := dynamodb.New(session.Must(session.NewSession()))
	existingEntries := getAllDynamoEntriesByVideoId(dynamoClient)

	for _, queryTerm := range queryTerms {
		allVideoIds := getYoutubeVideoIds(youTubeService, queryTerm)
		var newVideoIds []string

		log.Print("Filtering out existing video ids already in dynamodb")
		for _, videoId := range allVideoIds {
			if _, exists := existingEntries[videoId]; !exists {
				newVideoIds = append(newVideoIds, videoId)
			}
		}

		youtubeModels := filterYouTubeVideoIdsByViews(youTubeService, newVideoIds)

		for _, youtubeModel := range youtubeModels {
			log.Printf("Created model with id '%v' with views of '%v'", youtubeModel.VideoId, youtubeModel.ViewCount)
		}

		pushVideoIdsToDynamoDb(dynamoClient, youtubeModels)
	}
}

func getYouTubeService() *youtube.Service {
	log.Print("Getting YouTube service")

	apiKey := os.Getenv("YOUTUBE_API_TOKEN")

	service, err := youtube.NewService(context.Background(), option.WithAPIKey(apiKey))
	HandleError(err)

	return service
}

func getYoutubeVideoIds(youTubeService *youtube.Service, queryTerm string) []string {
	log.Printf("Getting ids query term '%v'", queryTerm)
	var videoIds []string

	serviceSearchCall := youTubeService.Search.
		List([]string{"snippet"}).
		Q(queryTerm).
		MaxResults(50).
		Type("video").
		PublishedAfter(time.Now().Add(-48 * time.Hour).Format(time.RFC3339)).
		VideoEmbeddable("true")

	serviceSearchCallResponse, err := serviceSearchCall.Do()
	HandleError(err)

	for _, item := range serviceSearchCallResponse.Items {
		if item.Snippet.LiveBroadcastContent != "none" {
			continue
		}
		videoIds = append(videoIds, item.Id.VideoId)
	}

	return videoIds
}

func filterYouTubeVideoIdsByViews(youTubeService *youtube.Service, videoIds []string) []YouTubeModel {
	log.Print("Filtering video ids by view count")

	var youtubeModels []YouTubeModel
	formattedVideoIds := strings.Join(videoIds[:],",")
	maxViewCount, err := strconv.ParseUint(os.Getenv("MAXIMUM_VIEW_COUNT"), 10, 64)
	HandleError(err)

	serviceVideoCall := youTubeService.Videos.
		List([]string{"statistics"}).
		Id(formattedVideoIds).
		MaxResults(50)

	serviceVideoCallResponse, err := serviceVideoCall.Do()
	HandleError(err)

	for _, item := range serviceVideoCallResponse.Items {
		if item.Statistics.ViewCount <= maxViewCount {
			id := uuid.New().String()
			youtubeModels = append(youtubeModels, YouTubeModel{ Id: id, VideoId: item.Id, ViewCount: strconv.Itoa(int(item.Statistics.ViewCount))})
		}
	}

	return youtubeModels
}

func getAllDynamoEntriesByVideoId(dynamoClient *dynamodb.DynamoDB) map[string]YouTubeModel {
	tableName := os.Getenv("DYNAMO_TABLE_NAME")
	log.Printf("Getting all entries by Id from dynamo table : '%s'", tableName)

	result, err := dynamoClient.Scan(&dynamodb.ScanInput{
		TableName:                 aws.String(tableName),
	})
	HandleError(err)

	youtubeModels := make(map[string]YouTubeModel)
	for _, item := range result.Items {
		youtubeModel := YouTubeModel{}

		err = dynamodbattribute.UnmarshalMap(item, &youtubeModel)
		HandleError(err)
		youtubeModels[youtubeModel.VideoId] = youtubeModel
	}

	log.Printf("Retrieved '%b' models", len(youtubeModels))
	return youtubeModels
}

func pushVideoIdsToDynamoDb(dynamoClient *dynamodb.DynamoDB, youTubeModels []YouTubeModel) {
	tableName := os.Getenv("DYNAMO_TABLE_NAME")
	log.Printf("Pushing ids to dynamo table : '%s'", tableName)

	for _, youTubeModel := range youTubeModels {
		attributeValue, err := dynamodbattribute.MarshalMap(youTubeModel)
		HandleError(err)

		_, err = dynamoClient.PutItem(&dynamodb.PutItemInput{
			Item:      attributeValue,
			TableName: aws.String(tableName),
		})
		HandleError(err)
	}
}

func HandleError(err error) {
	if err != nil {
		panic(fmt.Sprintf("Error encountered. Log : %v", err))
	}
}
