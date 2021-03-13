import React, { Component } from 'react';
import './Header.css'

class Header extends Component {
    render() {
        return (
            <div className="header-container container-fluid">
                <h1 className="title">ZeroTube</h1>
            </div>
        );
    }
}

export default Header