import React, { Component } from 'react';
import YouTubeVideo from "./components/YouTubeVideo";

class App extends Component {
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

        //// Uncomment for testing without hitting the API
        // this.setState({ videoInfo: {
        //         VideoId: "BY8KsQFmyUM",
        //         ViewCount: "99"
        // }})
    }

    render() {
        return (
            <YouTubeVideo videoInfo={this.state.videoInfo} />
        );
    }
}

export default App;