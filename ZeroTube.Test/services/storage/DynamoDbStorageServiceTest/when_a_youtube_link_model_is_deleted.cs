using Moq;
using NUnit.Framework;
using ZeroTube.infrastructure.services.storage.dynamodb;
using ZeroTube.infrastructure.services.storage.models;

namespace ZeroTube.Test.services.storage.DynamoDbStorageServiceTest
{
    public class when_a_model_is_deleted : DynamoDbStorageServiceTestBase
    {
        private YouTubeLinkModel _modelToDelete = new YouTubeLinkModel { Id = "https://www.youtube.com/watch?v=dQw4w9WgXcQ", ViewCount = 10 };
        private DynamoDbStorageService _testClient;

        [SetUp]
        public new void Setup()
        {
            base.Setup();
            SetupDeleteAsyncMock();
            _testClient = new DynamoDbStorageService(MockDynamoContext.Object, MockBatchWriteAdapter.Object);
            DynamoLocalStorage.Add(_modelToDelete);
            _testClient.Delete(_modelToDelete.Id);
        }

        [Test]
        public void it_should_be_removed_from_storage()
        {
            MockDynamoContext.Verify(mock => mock.DeleteAsync(_modelToDelete.Id, default), Times.Once(), "DeleteAsync method has been called more/less than once");
            Assert.AreEqual(0, DynamoLocalStorage.Count, "Assert entry was removed");
        }
    }
}