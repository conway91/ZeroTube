import React from 'react';
import ReactDOM from 'react-dom';
import './index.css';
import YouTubeVideo from './components/YouTubeVideo';
import Header from './components/Header';
import Footer from './components/Footer';

ReactDOM.render(
  <React.StrictMode>
      <Header />
      <YouTubeVideo />
      <Footer />
  </React.StrictMode>,
  document.getElementById('root')
);