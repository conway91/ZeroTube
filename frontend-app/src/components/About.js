import React, { Component } from 'react';
import './About.css'

class About extends Component {
    render() {
        return (
            <div className="about-container container">
                <p><a href="https://www.youtube.com" target="_blank">YouTube</a> is a free video-sharing website that makes it easy to watch online videos. You can even create and upload your videos to share with others. It also promotes and recommends user-uploaded videos based on popularity, views, and relevance. But have you ever wondered about the videos that have no views? Videos that no one else in the world has viewed yet? YouTube does not give you an option to filter videos based on views so this is not an option using the main website or API.</p>
                <p><a href="https://zerotube.net" target="_blank">ZeroTube.net</a> is an open-source website that allows users to get a randomly selected video that has zero (or as close to zero as possible) views. Each refresh of the page loads a new video. The purpose of this passion project is to explore the opposite side of YouTube. The part that no one, quite literally, has seen before.</p>
                <p>Please visit <a href="https://github.com/conway91/ZeroTube" target="_blank">the GitHub page</a> for more details.</p>
            </div>
        );
    }
}

export default About