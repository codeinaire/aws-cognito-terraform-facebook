import React from "react";
import AWS from 'aws-sdk';
import { CognitoUser, AuthenticationDetails } from "amazon-cognito-identity-js";
import { Formik } from "formik";
import cognito, { USER_POOL_URL, IDENTITY_POOL_ID } from "./cognitoConfig";

const SignIn = () => (
  <div>
    <Formik
      initialValues={{ username: "", password: "" }}
      onSubmit={(values, { setSubmitting }) => {
        const userPool = {
          Username: values.username,
          Pool: cognito
        }
        const formValues = {
          Username: values.username,
          Password: values.password
        }

        const authenticationDetails = new AuthenticationDetails(formValues);

        const cognitoUser = new CognitoUser(userPool);

        cognitoUser.authenticateUser(authenticationDetails, {
          onSuccess: result => {
            const idToken = result.getIdToken().getJwtToken();
            const loginsObj = {
              [USER_POOL_URL]: idToken
            }

            console.log('ID TOKEN', idToken);

            AWS.config.credentials = new AWS.CognitoIdentityCredentials({
              IdentityPoolId : IDENTITY_POOL_ID, // your identity pool id here
              Logins : loginsObj
            })
            AWS.config.credentials.refresh((error) => {
              if (error) {
                   console.error('this is the error', error);
              } else {
                const accessKeyId = AWS.config.credentials.accessKeyId;
                const secretAccessKey = AWS.config.credentials.secretAccessKey;
                const sessionToken = AWS.config.credentials.sessionToken;
                console.log('accessKey', accessKeyId);
                console.log('secretKey', secretAccessKey);
                console.log('sessionToken', sessionToken);

                // Instantiate aws sdk service objects now that the credentials have been updated.
                // example: var s3 = new AWS.S3();
                console.log('Successfully logged!');
              }
          });

          },
          onFailure: err => {
            console.log(`This is the error ${err}`);
          }
        });
        setSubmitting(false);
      }}
    >
      {({
        values,
        errors,
        touched,
        handleChange,
        handleBlur,
        handleSubmit,
        isSubmitting
        /* and other goodies */
      }) => (
        <form onSubmit={handleSubmit}>
          <label>
            username
            <input
              type="text"
              name="username"
              onChange={handleChange}
              onBlur={handleBlur}
              value={values.username}
            />
            {errors.username && touched.username && errors.username}
          </label>
          <label>
            Password
            <input
              type="password"
              name="password"
              onChange={handleChange}
              onBlur={handleBlur}
              value={values.password}
            />
            {errors.password && touched.password && errors.password}
          </label>
          <button type="submit" disabled={isSubmitting}>
            Submit
          </button>
        </form>
      )}
    </Formik>
  </div>
)

export default SignIn;