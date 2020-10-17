using Moq;
using NUnit.Framework;
using ZeroTube.infrastructure.services.storage.dynamodb;
using ZeroTube.infrastructure.services.models;

namespace ZeroTube.infrastructure.test.services.storage.DynamoDbStorageServiceTest
{
    public class when_a_model_is_queried_by_id : DynamoDbStorageServiceTestBase
    {
        private YouTubeLinkModel _modelToQuery = new YouTubeLinkModel { Id = "https://www.youtube.com/watch?v=dQw4w9WgXcQ", ViewCount = 10 };
        private DynamoDbStorageService _testClient;
        private YouTubeLinkModel _queriedOutModel;

        [SetUp]
        public new void Setup()
        {
            base.Setup();
            SetupLoadAsyncMock();
            _testClient = new DynamoDbStorageService(MockDynamoContext.Object, MockBatchWriteAdapter.Object);
            DynamoLocalStorage.Add(_modelToQuery);
            _queriedOutModel = (YouTubeLinkModel)_testClient.GetById<IModel>(_modelToQuery.Id);
        }

        [Test]
        public void it_should_be_query_once()
        {
            MockDynamoContext.Verify(mock => mock.LoadAsync<IModel>(_modelToQuery.Id, default), Times.Once(), "LoadAsync method has been called more/less than once");
        }

        [Test]
        public void it_should_be_returned_with_the_right_values()
        {
            Assert.AreEqual(_modelToQuery.Id, _queriedOutModel.Id, "Assert stored models Id is correct");
            Assert.AreEqual(_modelToQuery.ViewCount, _queriedOutModel.ViewCount, "Assert stored models ViewCount is correct");
        }
    }
}