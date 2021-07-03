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
        fetch('https://9jt0cb12a9.execute-api.eu-west-1.amazonaws.com/zerotube/random')
            .then(res => res.json())
            .then((data) => {
                this.setState({ videoInfo: data })
            })
            .catch(console.log)

        // Uncomment for testing without hitting the API
        // this.setState({ videoInfo: {
        //         VideoId: "BY8KsQFmyUM",
        //         ViewCount: "99"
        // }})
    }

    render() {
        return (
            <div className="container youtube-container">
                <div className="embed-responsive embed-responsive-16by9">
                    <iframe className="embed-responsive-item" id="youtubeVideo" title="youtubeVideo" allow='autoplay' allowfullscreen="0"
                            src={"https://www.youtube.com/embed/" + this.state.videoInfo['VideoId'] + "?autoplay=1?controls=0"}
                    />
                </div>
                <p>Video views : { this.state.videoInfo['ViewCount'] }</p>
            </div>
        );
    }
}

export default YouTubeVideo