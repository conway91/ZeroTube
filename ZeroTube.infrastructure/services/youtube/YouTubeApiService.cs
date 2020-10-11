using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Google.Apis.Services;
using Google.Apis.YouTube.v3;
using ZeroTube.infrastructure.services.models;

namespace ZeroTube.infrastructure.services.youtube
{
    public class YouTubeApiService : IYouTubeApiService
    {
        private readonly YouTubeService _youtubeService;

        public YouTubeApiService(string apiToken)
        {
            _youtubeService = new YouTubeService(new BaseClientService.Initializer()
            {
                ApiKey = apiToken,
                ApplicationName = "ZeroTube"
            });
        }

        public IList<YouTubeLinkModel> GetModelsFromSearchTerm(string searchTerm)
        {
            var videoIds = GetVideoIdsFromSearchTermAsync(searchTerm).Result;
            var youTubeModels = GetModelsFromVideoIdsAsync(videoIds).Result;

            if (youTubeModels?.Any() != true)
            {
                // TODO : Make custom exception
                throw new Exception("No youtube modles returned");
            }

            return youTubeModels;
        }

        private async Task<string> GetVideoIdsFromSearchTermAsync(string searchTerm)
        {
            var searchRequest = _youtubeService.Search.List("snippet");
            searchRequest.Q = searchTerm;
            searchRequest.MaxResults = 50;
            searchRequest.Type = "video";
            searchRequest.PublishedAfter = DateTime.Today.AddDays(-2);
            searchRequest.VideoEmbeddable = SearchResource.ListRequest.VideoEmbeddableEnum.True__;

            var searchResponse = await searchRequest.ExecuteAsync();
            var filteredVideos = searchResponse.Items.Where(_ => _.Snippet.LiveBroadcastContent == "none");
            var videoIds = string.Join(",", filteredVideos.Select(_ => _.Id.VideoId));

            return videoIds;
        }

        private async Task<List<YouTubeLinkModel>> GetModelsFromVideoIdsAsync(string videoIds)
        {
            var listRequest = _youtubeService.Videos.List("statistics");
            listRequest.Id = videoIds;
            listRequest.MaxResults = 50;

            var listResponse = await listRequest.ExecuteAsync();
            var youtubeModels = listResponse.Items.Select(_ => new YouTubeLinkModel { Id = _.Id, ViewCount = (int)_.Statistics.ViewCount }).ToList();

            return youtubeModels;
        }
    }
}
