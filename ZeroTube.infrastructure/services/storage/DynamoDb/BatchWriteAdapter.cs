using System.Collections.Generic;
using Amazon.DynamoDBv2.DataModel;
using ZeroTube.infrastructure.services.models;

namespace ZeroTube.infrastructure.services.storage.dynamodb
{
    public class BatchWriteAdapter : IBatchWriteAdapter
    {
        private readonly IDynamoDBContext _dynamoContext;

        public BatchWriteAdapter(IDynamoDBContext dynamoContext)
        {
            _dynamoContext = dynamoContext;
        }

        public void BatchInsert<T>(List<T> models) where T : IModel
        {
            var modelsBatch = _dynamoContext.CreateBatchWrite<T>();
            modelsBatch.AddPutItems(models);
            modelsBatch.ExecuteAsync();
        }
    }
}
