package main

import (
	"context"
	"encoding/json"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/google/uuid"
	"log"
	"net/http"
)

type YouTubeModel struct {
	Id string
	VideoId string
	ViewCount string
}

func main() {
	lambda.Start(HandleRequest)
}

func HandleRequest(ctx context.Context) (events.APIGatewayProxyResponse, error) {
	js, err := json.Marshal(YouTubeModel{Id: uuid.New().String(), VideoId: "hQyzEyIf7P0", ViewCount: "5"})
	if err != nil {
		return serverError(err)
	}

	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Body:       string(js),
	}, nil
}

func serverError(err error) (events.APIGatewayProxyResponse, error) {
	log.Printf("Server Error : '%s'", err)
	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusInternalServerError,
		Body:       http.StatusText(http.StatusInternalServerError),
	}, nil
}
