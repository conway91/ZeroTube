using System.Collections.Generic;
using Amazon.DynamoDBv2.DataModel;
using ZeroTube.infrastructure.services.models;

namespace ZeroTube.infrastructure.services.storage.dynamodb
{
    public class DynamoDbStorageService : IStorageService
    {
        private readonly IDynamoDBContext _dynamoContext;
        private readonly IBatchWriteAdapter _batchWriteAdapter;

        public DynamoDbStorageService(IDynamoDBContext dynamoContext, IBatchWriteAdapter batchWriteAdapter)
        {
            _dynamoContext = dynamoContext;
            _batchWriteAdapter = batchWriteAdapter;
        }

        public T GetById<T>(string id) where T : IModel
        {
            return _dynamoContext.LoadAsync<T>(id).Result;
        }

        public async void Insert<T>(T model) where T : IModel
        {
            await _dynamoContext.SaveAsync(model);
        }

        public void MultiInsert<T>(List<T> models) where T : IModel
        {
            _batchWriteAdapter.BatchInsert(models);
        }

        public async void Delete(string id)
        {
            await _dynamoContext.DeleteAsync(id);
        }

    }
}
