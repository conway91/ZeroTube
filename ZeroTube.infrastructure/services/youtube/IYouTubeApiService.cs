using System.Collections.Generic;
using ZeroTube.infrastructure.services.models;

namespace ZeroTube.infrastructure.services.youtube
{
    public interface IYouTubeApiService
    {
        public IList<YouTubeLinkModel> GetModelsFromSearchTerm(string searchTerm);
    }
}
