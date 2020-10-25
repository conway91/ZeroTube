using Amazon.DynamoDBv2.DataModel;

namespace ZeroTube.infrastructure.services.models
{
    [DynamoDBTable("ZeroTubeLinks")]
    public class YouTubeLinkModel : IModel
    {
        [DynamoDBHashKey]
        public string Id { get; set; }

        public int ViewCount { get; set; }
    }
}
