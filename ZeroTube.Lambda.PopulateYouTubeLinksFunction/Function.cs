using System.Collections.Generic;
using System.Linq;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.DataModel;
using Amazon.Lambda.Core;
using Amazon.Runtime;
using ZeroTube.infrastructure.helpers;
using ZeroTube.infrastructure.services.models;
using ZeroTube.infrastructure.services.storage;
using ZeroTube.infrastructure.services.storage.dynamodb;
using ZeroTube.infrastructure.services.youtube;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace ZeroTube.Lambda.PopulateYouTubeLinksFunction
{
    // TODO : This class needs refactored to be testable and have dependancy injection for storage and api services
    public class Function
    {
        public void FunctionHandler(ILambdaContext context)
        {
            var searchTerms = LambdaHelpers.GetEnvVar("SEARCH_TERMS");
            var minimumViewCount = int.Parse(LambdaHelpers.GetEnvVar("MINIMUM_VIEW_COUNT"));

            var youTubeService = GetYouTubeApiService();
            var storageService = GetStorageService();

            foreach (var searchTerm in searchTerms.Split(','))
            {
                LambdaLogger.Log($"Querying on search term '{searchTerm}'");
                var videos = GetYouTubeVideosByView(youTubeService, searchTerm, minimumViewCount);
                storageService.MultiInsert(videos);
                LambdaLogger.Log($"Query and insert complete for '{searchTerm}'");
            }
        }

        private List<YouTubeLinkModel> GetYouTubeVideosByView(IYouTubeApiService apiService, string searchTerm, int minimumViewCount)
        {
            var unfliteredResults = apiService.GetModelsFromSearchTerm(searchTerm);
            return unfliteredResults.Where(_ => _.ViewCount <= minimumViewCount).ToList();
        }

        // TODO : Move to DI
        private YouTubeApiService GetYouTubeApiService()
        {
            var youTubeApiToken = LambdaHelpers.GetEnvVar("YOUTUBE_API_TOKEN");
            return new YouTubeApiService(youTubeApiToken);
        }

        // TODO : Move to DI
        private IStorageService GetStorageService()
        {
            var awsAcessKey = LambdaHelpers.GetEnvVar("AWS_ACCESS_KEY");
            var awsSecretAcessKey = LambdaHelpers.GetEnvVar("AWS_SECRET_ACCESS_KEY");
            var awsCredentials = new BasicAWSCredentials(awsAcessKey, awsSecretAcessKey);

            var dynamoClient = new AmazonDynamoDBClient(awsCredentials);
            var dynamoContext = new DynamoDBContext(dynamoClient);
            var dynamoBatchAdapter = new BatchWriteAdapter(dynamoContext);

            return new DynamoDbStorageService(dynamoContext, dynamoBatchAdapter);
        }
    }
}
