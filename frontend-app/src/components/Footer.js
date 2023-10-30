import React, { Component } from 'react';
import './Footer.css'

class Footer extends Component {
    render() {
        const { changeState } = this.props;
        return (
            <div className="footer-container container">
                <span>
                    <span className="change-state" onClick={()=> changeState("video")}>Home</span>
                    <span className="divider">|</span>
                    <span className="change-state" onClick={()=> changeState("about")}>About</span>
                    <span className="divider">|</span>
                    <a href="https://github.com/conway91/ZeroTube" target="_blank" rel="noreferrer">GitHub</a>
                </span>
                <br />
                <p>2023</p>
            </div>
        );
    }
}

export default Footer