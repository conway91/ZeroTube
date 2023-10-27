import React, { Component } from 'react';
import './Header.css'

class Header extends Component {
    render() {
        const { changeState } = this.props;
        return (
            <div className="header-container container-fluid">
                <h1 className="title"><a href="/">ZeroTube</a></h1>
            </div>
        );
    }
}

export default Header