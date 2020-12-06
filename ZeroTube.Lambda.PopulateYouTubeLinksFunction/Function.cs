using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Amazon.Lambda.Core;
using Amazon.S3;
using Amazon.S3.Transfer;
using ZeroTube.infrastructure.helpers;
using ZeroTube.infrastructure.services.models;
using ZeroTube.infrastructure.services.youtube;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace ZeroTube.Lambda.PopulateYouTubeLinksFunction
{
    public class Function
    {
        private const string FileName = "zerotube-videos-data";

        public void FunctionHandler(ILambdaContext context)
        {
            var searchTerms = LambdaHelpers.GetEnvVar("SEARCH_TERMS");
            var siteBucketName = LambdaHelpers.GetEnvVar("SITE_BUCKET_NAME");
            var maximumViewCount = int.Parse(LambdaHelpers.GetEnvVar("MAXIMUM_VIEW_COUNT"));

            var youTubeService = GetYouTubeApiService();

            var totalVideos = new List<YouTubeLinkModel>();
            foreach (var searchTerm in searchTerms.Split(','))
            {
                var trimmedSearchTerm = searchTerm.Trim();
                totalVideos.AddRange(GetYouTubeVideosByView(youTubeService, trimmedSearchTerm, maximumViewCount));
            }
            
            LambdaLogger.Log($"Creating general video s3 file.");
            CreateVideoFile(totalVideos.OrderBy(_ => _.ViewCount).Take(100).ToList());
            PushVideoFileToS3(siteBucketName).Wait();
        }

        private List<YouTubeLinkModel> GetYouTubeVideosByView(IYouTubeApiService apiService, string searchTerm, int maximumViewCount)
        {
            LambdaLogger.Log($"Querying on search term '{searchTerm}'");

            var unfilteredResults = apiService.GetModelsFromSearchTerm(searchTerm);
            return unfilteredResults.Where(_ => _.ViewCount <= maximumViewCount).ToList();
        }

        private YouTubeApiService GetYouTubeApiService()
        {
            var youTubeApiToken = LambdaHelpers.GetEnvVar("YOUTUBE_API_TOKEN");
            return new YouTubeApiService(youTubeApiToken);
        }
        
        private void CreateVideoFile(List<YouTubeLinkModel> videos)
        {
            LambdaLogger.Log($"Saving file to '/tmp/{FileName}'");

            if(File.Exists($"/tmp/{FileName}"))
                File.Delete($"/tmp/{FileName}");
            
            using(var writer = new StreamWriter($"/tmp/{FileName}"))
            {
                foreach (var video in videos)
                    writer.WriteLine(video.Id);
            }
        }

        private static async Task PushVideoFileToS3(string siteBucketName)
        {
            LambdaLogger.Log($"Uploading to bucket '{siteBucketName}'");

            var s3Client = new AmazonS3Client();
            var fileTransferUtility = new TransferUtility(s3Client);
            await fileTransferUtility.UploadAsync($"/tmp/{FileName}", siteBucketName);
        }
    }
}
