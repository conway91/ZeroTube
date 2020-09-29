using System;
using System.Collections.Generic;
using ZeroTube.infrastructure.services.storage.models;

namespace ZeroTube.infrastructure.services.storage
{
    public interface IStorageService
    {
        public T GetById<T>(string id) where T : IModel;
        public void Insert(IModel model);
        public void Insert(IList<IModel> models);
        public void Delete(string id);
    }
}
