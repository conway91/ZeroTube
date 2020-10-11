using System.Collections.Generic;
using Amazon.DynamoDBv2.DataModel;
using ZeroTube.infrastructure.services.storage.models;

namespace ZeroTube.infrastructure.services.storage
{
    public class DynamoDbStorageService : IStorageService
    {
        private readonly IDynamoDBContext _dynamoContext;

        public DynamoDbStorageService(IDynamoDBContext dynamoContext)
        {
            _dynamoContext = dynamoContext;
        }

        public T GetById<T>(string id) where T : IModel
        {
            return _dynamoContext.LoadAsync<T>(id).Result;
        }

        public async void Insert(IModel model)
        {
            await _dynamoContext.SaveAsync(model);
        }

        public void Insert(IList<IModel> models)
        {
            var modelsBatch = _dynamoContext.CreateBatchWrite<IModel>();
            modelsBatch.AddPutItems(models);
            modelsBatch.ExecuteAsync();
        }

        public async void Delete(string id)
        {
            await _dynamoContext.DeleteAsync(id);
        }

    }
}
