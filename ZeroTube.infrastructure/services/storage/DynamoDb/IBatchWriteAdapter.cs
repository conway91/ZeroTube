using System.Collections.Generic;
using ZeroTube.infrastructure.services.storage.models;

namespace ZeroTube.infrastructure.services.storage.dynamodb
{
    public interface IBatchWriteAdapter
    {
        public void BatchInsert<T>(List<T> models) where T : IModel;
    }
}
