using Amazon.DynamoDBv2.DataModel;

namespace ZeroTube.infrastructure.services.storage.models
{
    [DynamoDBTable("YouTubeLink")]
    public class YouTubeLinkModel : IModel
    {
        [DynamoDBHashKey]
        public string Id { get; set; }

        public int ViewCount { get; set; }
    }
}
