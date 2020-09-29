using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Amazon.DynamoDBv2.DataModel;
using Moq;
using NUnit.Framework;
using ZeroTube.infrastructure.services.storage.models;

namespace ZeroTube.Test.services.storage.DynamoDbStorageServiceTest
{
    public abstract class DynamoDbStorageServiceTestBase
    {
        protected List<IModel> DynamoLocalStorage { get; set; }
        protected Mock<IDynamoDBContext> MockDynamoContext { get; set; }

        [SetUp]
        public void Setup()
        {
            DynamoLocalStorage = new List<IModel>();
            MockDynamoContext = new Mock<IDynamoDBContext>();
        }

        protected void SetupLoadAsyncMock()
        {
            MockDynamoContext.Setup(p => p.LoadAsync<IModel>(It.IsAny<string>(), It.IsAny<CancellationToken>())).Returns((string input, CancellationToken token) => Task.FromResult(DynamoLocalStorage.FirstOrDefault(x => x.Id == input)));
        }

        protected void SetupSaveAsyncMock()
        {
            MockDynamoContext.Setup(p => p.SaveAsync(It.IsAny<IModel>(), It.IsAny<CancellationToken>())).Callback((IModel model, CancellationToken token) => DynamoLocalStorage.Add(model));
        }

        protected void SetupDeleteAsyncMock()
        {
            MockDynamoContext.Setup(p => p.DeleteAsync(It.IsAny<string>(), It.IsAny<CancellationToken>())).Callback((string id, CancellationToken token) => DynamoLocalStorage.Remove(DynamoLocalStorage.SingleOrDefault(_ => _.Id == id)));
        }
    }
}