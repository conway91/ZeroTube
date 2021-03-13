import React, { Component } from 'react';
import './Footer.css'

class Footer extends Component {
    render() {
        return (
            <div className="footer-container container">
                <span>
                    <a> Home</a> |
                    <a> About</a> |
                    <a> GitHub</a>
                </span>
                <br />
                <p>2021</p>
            </div>
        );
    }
}

export default Footer