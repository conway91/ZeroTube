import React, { Component } from 'react';
import YouTubeVideo from './YouTubeVideo';
import Header from './Header';
import Footer from './Footer';
import About from './About';

class MainWrapper extends Component {
    constructor(props) {
        super();
        this.state = { displaySection: "video" }
    }

    changeState = (newState) => {
        this.setState({ displaySection: newState });
    }

    render() {
        return (
            <React.Fragment>
                <Header />

                {this.state.displaySection === 'video' && (
                    <YouTubeVideo />
                )}

                {this.state.displaySection === 'about' && (
                    <About />
                )}

                <Footer changeState={this.changeState}/>
            </React.Fragment>
        );
    }
}

export default MainWrapper