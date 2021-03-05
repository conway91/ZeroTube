import React from 'react'

const YouTubeVideo = ({ videoInfo }) => {
    return (
        <div>
            <h1>YouTube Video</h1>
             <p>Video Id : { videoInfo['VideoId'] }</p>
            <iframe id="youtubeVideo" title="youtubeVideo" width="640" height="360"
    src={"https://www.youtube.com/embed/" + videoInfo['VideoId'] + "?autoplay=1"}
    frameBorder="0"/>
             <p>Video views : { videoInfo['ViewCount'] }</p>
        </div>
    )
};

export default YouTubeVideo