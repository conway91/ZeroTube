using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Amazon.DynamoDBv2.DataModel;
using Moq;
using NUnit.Framework;
using ZeroTube.infrastructure.services.storage.dynamodb;
using ZeroTube.infrastructure.services.storage.models;

namespace ZeroTube.Test.services.storage.DynamoDbStorageServiceTest
{
    public abstract class DynamoDbStorageServiceTestBase
    {
        protected List<IModel> DynamoLocalStorage { get; set; }
        protected Mock<IDynamoDBContext> MockDynamoContext { get; set; }
        protected Mock<IBatchWriteAdapter> MockBatchWriteAdapter { get; set; }

        [SetUp]
        public void Setup()
        {
            DynamoLocalStorage = new List<IModel>();
            MockDynamoContext = new Mock<IDynamoDBContext>();
            MockBatchWriteAdapter = new Mock<IBatchWriteAdapter>(); ;
        }

        protected void SetupLoadAsyncMock()
        {
            MockDynamoContext.Setup(p => p.LoadAsync<IModel>(It.IsNotNull<string>(), It.IsAny<CancellationToken>())).Returns((string input, CancellationToken token) => Task.FromResult(DynamoLocalStorage.FirstOrDefault(x => x.Id == input)));
        }

        protected void SetupInsertAsyncMock()
        {
            MockDynamoContext.Setup(p => p.SaveAsync(It.IsNotNull<IModel>(), It.IsAny<CancellationToken>())).Callback((IModel model, CancellationToken token) => DynamoLocalStorage.Add(model));
        }

        protected void SetupMultiInsertAsyncMock()
        {
            MockBatchWriteAdapter.Setup(p => p.BatchInsert(It.IsNotNull<List<IModel>>())).Callback((List<IModel> models) => DynamoLocalStorage.AddRange(models));
        }

        protected void SetupDeleteAsyncMock()
        {
            MockDynamoContext.Setup(p => p.DeleteAsync(It.IsNotNull<string>(), It.IsAny<CancellationToken>())).Callback((string id, CancellationToken token) => DynamoLocalStorage.Remove(DynamoLocalStorage.SingleOrDefault(_ => _.Id == id)));
        }
    }
}