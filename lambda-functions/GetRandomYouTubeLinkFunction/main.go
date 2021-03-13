package main

import (
	"context"
	"encoding/json"
	"fmt"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/google/uuid"
	"github.com/pkg/errors"
	"log"
	"net/http"
	"os"
)

type YouTubeModel struct {
	Id        string
	VideoId   string
	ViewCount string
}

func main() {
	lambda.Start(HandleRequest)
}

func HandleRequest(ctx context.Context) (events.APIGatewayProxyResponse, error) {
	youTubeModel, err := getDynamoEntry()
	if err != nil {
		return serverError(err)
	}

	js, err := json.Marshal(youTubeModel)
	if err != nil {
		return serverError(err)
	}

	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Body:       string(js),
		Headers:    getResponseHeaders(),
	}, nil
}

func getDynamoEntry() (YouTubeModel, error) {
	dynamoClient := dynamodb.New(session.Must(session.NewSession()))
	lastKeyEvaluated := uuid.New().String()

	result, err := dynamoClient.Scan(&dynamodb.ScanInput{
		TableName: aws.String(os.Getenv("DYNAMO_TABLE_NAME")),
		ExclusiveStartKey: map[string]*dynamodb.AttributeValue{
			"Id": {
				S: aws.String(lastKeyEvaluated),
			},
		},
		Limit: aws.Int64(1),
	})

	if err != nil {
		return YouTubeModel{}, err
	}

	if len(result.Items) != 1 {
		errorMessage := fmt.Sprintf("1 result not returned from db, total results : '%b'", len(result.Items))
		log.Printf(errorMessage)
		return YouTubeModel{}, errors.New(errorMessage)
	}

	return YouTubeModel{Id: *result.Items[0]["Id"].S, VideoId: *result.Items[0]["VideoId"].S, ViewCount: *result.Items[0]["ViewCount"].S}, nil
}

func serverError(err error) (events.APIGatewayProxyResponse, error) {
	log.Printf("Server Error : '%s'", err)
	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusInternalServerError,
		Body:       http.StatusText(http.StatusInternalServerError),
		Headers:    getResponseHeaders(),
	}, nil
}

func getResponseHeaders() map[string]string {
	headers := make(map[string]string)
	headers["Access-Control-Allow-Origin"] = "*"
	headers["Access-Control-Allow-Headers"] = "*"
	headers["Access-Control-Allow-Methods"] = "OPTIONS,GET"

	return headers
}
