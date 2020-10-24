import React from 'react';
import ReactDOM from 'react-dom';
import './index.css';
import { make as App } from './App.bs';

ReactDOM.render(
  React.createElement(
    React.StrictMode,
    undefined,
    React.createElement(App, undefined)
  ),
  document.getElementById('root')
);
