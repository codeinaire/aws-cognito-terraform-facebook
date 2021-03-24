import React from 'react';
import AWS from 'aws-sdk';
import FacebookSignIn from 'react-facebook-login';
import { IDENTITY_POOL_ID } from "./cognitoConfig";


const responseFacebook = (response) => {
  // Check if the user logged in successfully.
  if (response) {
    // Add the Facebook access token to the Cognito credentials login map
    // we pass in the accessToken from the fb response into our `CognitoIdentityCredentials`
    AWS.config.credentials = new AWS.CognitoIdentityCredentials({
   // we are logging into an AWS federated identify pool, for facebook login
      IdentityPoolId: IDENTITY_POOL_ID,
      Logins: {
         'graph.facebook.com': response.accessToken
      }
      })

    // AWS Cognito Sync to sync Facebook
    // aka refreshing the credentials to use thorughout our app
    AWS.config.credentials.get((error, response) => {
      if (error) {
           console.error('this is the error', error);
      } else {
        const accessKeyId = AWS.config.credentials.accessKeyId;
        const secretAccessKey = AWS.config.credentials.secretAccessKey;
        const sessionToken = AWS.config.credentials.sessionToken;

        // Instantiate aws sdk service objects now that the credentials have been updated.
        // example: var s3 = new AWS.S3();
        console.log('secretAccessKey', secretAccessKey);
        console.log('accessKeyId!', accessKeyId);
        console.log('sessionToken', sessionToken);
      }
    });
    console.log('You are now logged in.');

  } else {
    console.log('There was a problem logging you in.');
  }
}

const FacebookSignInComponent = () => (
  <div>
    <FacebookSignIn
        appId="2795493367128128"
        autoLoad={false}
        fields="name,email,picture"
        callback={responseFacebook}
      />
  </div>
)

export default FacebookSignInComponent;