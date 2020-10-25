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
    public class Function
    {
        public void FunctionHandler(ILambdaContext context)
        {
            var searchTerms = LambdaHelpers.GetEnvVar("SEARCH_TERMS");
            var maximumViewCount = int.Parse(LambdaHelpers.GetEnvVar("MAXIMUM_VIEW_COUNT"));

            var youTubeService = GetYouTubeApiService();
            var storageService = GetStorageService();

            foreach (var searchTerm in searchTerms.Split(','))
            {
                var trimedSearchTerm = searchTerm.Trim();
                LambdaLogger.Log($"Querying on search term '{trimedSearchTerm}'");
                var videos = GetYouTubeVideosByView(youTubeService, trimedSearchTerm, maximumViewCount);
                storageService.MultiInsert(videos);
                LambdaLogger.Log($"Query and insert complete for '{trimedSearchTerm}'");
            }
        }

        private List<YouTubeLinkModel> GetYouTubeVideosByView(IYouTubeApiService apiService, string searchTerm, int maximumViewCount)
        {
            var unfliteredResults = apiService.GetModelsFromSearchTerm(searchTerm);
            return unfliteredResults.Where(_ => _.ViewCount <= maximumViewCount).ToList();
        }

        private YouTubeApiService GetYouTubeApiService()
        {
            var youTubeApiToken = LambdaHelpers.GetEnvVar("YOUTUBE_API_TOKEN");
            return new YouTubeApiService(youTubeApiToken);
        }

        private IStorageService GetStorageService()
        {
            var awsAcessKey = LambdaHelpers.GetEnvVar("DYNAMODB_AWS_ACCESS_KEY");
            var awsSecretAcessKey = LambdaHelpers.GetEnvVar("DYNAMODB_AWS_SECRET_ACCESS_KEY");
            var awsCredentials = new BasicAWSCredentials(awsAcessKey, awsSecretAcessKey);

            var dynamoClient = new AmazonDynamoDBClient(awsCredentials);
            var dynamoContext = new DynamoDBContext(dynamoClient);
            var dynamoBatchAdapter = new BatchWriteAdapter(dynamoContext);

            return new DynamoDbStorageService(dynamoContext, dynamoBatchAdapter);
        }
    }
}
