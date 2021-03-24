import React from 'react';
import logo from './logo.svg';
import './App.css';
import SignUp from './SignUp';
import SignIn from './SignIn';
import FacebookSignIn from './FacebookSignIn';

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <p>
          Edit <code>src/App.js</code> and save to reload.
        </p>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a>
        <SignUp />
        <SignIn />
        <FacebookSignIn />
      </header>
    </div>
  );
}

export default App;
