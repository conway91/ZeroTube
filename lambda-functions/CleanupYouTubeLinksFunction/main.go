package main

import (
	"context"
	"fmt"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"log"
	"os"
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
	currentYoutubeModels := getAllDynamoEntries()

	for _, currentYoutubeModel := range currentYoutubeModels {
		log.Printf("Model Id : '%s' Model VideoId : '%s' Model ViewCount : '%s'",
			currentYoutubeModel.Id, currentYoutubeModel.VideoId, currentYoutubeModel.ViewCount)
	}
}

func getAllDynamoEntries() []YouTubeModel {
	tableName := os.Getenv("DYNAMO_TABLE_NAME")
	log.Printf("Getting all entries from dynamo table : '%s'", tableName)
	dynamoClient := dynamodb.New(session.Must(session.NewSession()))

	result, err := dynamoClient.Scan(&dynamodb.ScanInput{
		TableName:                 aws.String(tableName),
	})
	HandleError(err)

	var youtubeModels []YouTubeModel
	for _, item := range result.Items {
		youtubeModel := YouTubeModel{}

		err = dynamodbattribute.UnmarshalMap(item, &youtubeModel)
		HandleError(err)
		if err != nil {
			fmt.Println("Got error unmarshalling:")
			fmt.Println(err.Error())
			os.Exit(1)
		}

		youtubeModels = append(youtubeModels, youtubeModel)
	}

	return youtubeModels
}

func HandleError(err error) {
	if err != nil {
		panic(fmt.Sprintf("Error encountered. Log : %v", err))
	}
}
