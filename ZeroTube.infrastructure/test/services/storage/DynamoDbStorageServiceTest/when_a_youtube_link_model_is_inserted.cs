using System.Linq;
using Moq;
using NUnit.Framework;
using ZeroTube.infrastructure.services.storage.dynamodb;
using ZeroTube.infrastructure.services.models;

namespace ZeroTube.infrastructure.test.services.storage.DynamoDbStorageServiceTest
{
    public class when_a_model_is_inserted : DynamoDbStorageServiceTestBase
    {
        private YouTubeLinkModel _modelToInsert = new YouTubeLinkModel { Id = "https://www.youtube.com/watch?v=dQw4w9WgXcQ", ViewCount = 10 };
        private DynamoDbStorageService _testClient;

        [SetUp]
        public new void Setup()
        {
            base.Setup();
            SetupInsertAsyncMock();
            _testClient = new DynamoDbStorageService(MockDynamoContext.Object, MockBatchWriteAdapter.Object);
            _testClient.Insert(_modelToInsert);
        }

        [Test]
        public void it_should_be_inserted_only_once()
        {
            MockDynamoContext.Verify(mock => mock.SaveAsync<IModel>(_modelToInsert, default), Times.Once(), "SaveAsync method has been called more/less than once");
            Assert.AreEqual(1, DynamoLocalStorage.Count, "Assert only one entry has been added");
        }

        [Test]
        public void it_should_be_stored_in_the_db_with_thew_correct_values()
        {
            var storedModel = (YouTubeLinkModel)DynamoLocalStorage.First();
            Assert.AreEqual(_modelToInsert.Id, storedModel.Id, "Assert stored models Id is correct");
            Assert.AreEqual(_modelToInsert.ViewCount, storedModel.ViewCount, "Assert stored models ViewCount is correct");
        }
    }
}