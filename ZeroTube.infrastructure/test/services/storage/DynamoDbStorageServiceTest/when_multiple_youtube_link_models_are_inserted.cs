using System.Collections.Generic;
using System.Linq;
using Moq;
using NUnit.Framework;
using ZeroTube.infrastructure.services.storage.dynamodb;
using ZeroTube.infrastructure.services.models;

namespace ZeroTube.infrastructure.test.services.storage.DynamoDbStorageServiceTest
{
    public class when_multiple_youtube_link_models_are_inserted : DynamoDbStorageServiceTestBase
    {
        private YouTubeLinkModel _modelToInsert1 = new YouTubeLinkModel { Id = "https://www.youtube.com/watch?v=dQw4w9WgXcQ1", ViewCount = 10 };
        private YouTubeLinkModel _modelToInsert2 = new YouTubeLinkModel { Id = "https://www.youtube.com/watch?v=dQw4w9WgXcQ2", ViewCount = 15 };
        private YouTubeLinkModel _modelToInsert3 = new YouTubeLinkModel { Id = "https://www.youtube.com/watch?v=dQw4w9WgXcQ3", ViewCount = 20 };
        private List<YouTubeLinkModel> _modelList;
        private DynamoDbStorageService _testClient;

        [SetUp]
        public new void Setup()
        {
            base.Setup();
            SetupMultiInsertAsyncMock();
            _testClient = new DynamoDbStorageService(MockDynamoContext.Object, MockBatchWriteAdapter.Object);
            _modelList = new List<YouTubeLinkModel> { _modelToInsert1, _modelToInsert2, _modelToInsert3 };
            _testClient.MultiInsert(_modelList);
        }

        [Test]
        public void it_should_be_inserted_only_once()
        {
            MockBatchWriteAdapter.Verify(mock => mock.BatchInsert(_modelList), Times.Once(), "BatchInsert method has been called more/less than once");
            Assert.AreEqual(3, DynamoLocalStorage.Count, "Assert all entires has been added");
        }

        [Test]
        public void it_should_be_stored_in_the_db_with_thew_correct_values()
        {
            CheckStoredModel(_modelToInsert1.Id, _modelToInsert1.ViewCount);
            CheckStoredModel(_modelToInsert2.Id, _modelToInsert2.ViewCount);
            CheckStoredModel(_modelToInsert3.Id, _modelToInsert3.ViewCount);
        }

        private void CheckStoredModel(string id, int viewCount)
        {
            var storedModel = (YouTubeLinkModel)DynamoLocalStorage.SingleOrDefault(_ => _.Id == id);

            Assert.NotNull(storedModel, $"Assert fetched model is not null with Id {id}");
            Assert.AreEqual(id, storedModel.Id, "Assert stored models Id is correct");
            Assert.AreEqual(viewCount, storedModel.ViewCount, "Assert stored models ViewCount is incorrect");
        }
    }
}