import React, { Component } from 'react';
import './YouTubeVideo.css'

class YouTubeVideo extends Component {
    constructor(props) {
        super(props);
        this.state = {
            videoInfo: ""
        };
    }

    componentDidMount() {
        // fetch('https://9jt0cb12a9.execute-api.eu-west-1.amazonaws.com/zerotube/random')
        //     .then(res => res.json())
        //     .then((data) => {
        //         this.setState({ videoInfo: data })
        //     })
        //     .catch(console.log)

        // Uncomment for testing without hitting the API
        this.setState({ videoInfo: {
                VideoId: "BY8KsQFmyUM",
                ViewCount: "99"
        }})
    }

    render() {
        return (
            <div className="youtube-video-container">
                <iframe id="youtubeVideo" title="youtubeVideo" width="640" height="360"
                        src={"https://www.youtube.com/embed/" + this.state.videoInfo['VideoId'] + "?autoplay=1"}
                        frameBorder="0"/>
                <p>Video views : { this.state.videoInfo['ViewCount'] }</p>
            </div>
        );
    }
}

export default YouTubeVideo