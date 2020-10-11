using System.Collections.Generic;
using ZeroTube.infrastructure.services.models;

namespace ZeroTube.infrastructure.services.storage
{
    public interface IStorageService
    {
        public T GetById<T>(string id) where T : IModel;
        public void Insert<T>(T model) where T : IModel;
        public void MultiInsert<T>(List<T> models) where T : IModel;
        public void Delete(string id);
    }
}
