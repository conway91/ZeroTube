using System;
using System.Collections.Generic;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using Amazon.Lambda.Core;


[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace ZeroTube.Lambda.GetYouTubeLinksFunction
{
    public class Function
    {
        public void FunctionHandler(ILambdaContext context)
        {
            GetRandomItem();
        }

        // TODO : Move this to be generic on the DynamoStorageSevrice
        private List<Dictionary<string, AttributeValue>> GetRandomItem()
        {
            var client = new AmazonDynamoDBClient();

            var lastKeyEvaluated = new Dictionary<string, AttributeValue>()
            {
                { "SortKey", new AttributeValue(Guid.NewGuid().ToString()) }
            };

            var request = new ScanRequest()
            {
                TableName = "ZeroTubeLinks",
                ExclusiveStartKey = lastKeyEvaluated,
                Limit = 1
            };

            var response = client.ScanAsync(request).Result;
            var entryResults = response.Items;

            var count = 1;
            foreach(var entry in entryResults)
            {
                LambdaLogger.Log($"Looping entry '{count}'");
                foreach (var entryValue in entry)
                {
                    LambdaLogger.Log($"Entry Key '{entryValue.Key}'");
                    LambdaLogger.Log($"Entry Value '{entryValue.Value}'");

                }
                count++;
            }

            return entryResults;
        }
    }
}
