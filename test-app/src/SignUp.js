import React from "react";
import { CognitoUserAttribute } from "amazon-cognito-identity-js";
import { Formik } from "formik";
import cognito from "./cognitoConfig";

const SignUp = () => (
  <div>
    <Formik
      initialValues={{ username: "", password: "", nickname: "" }}
      onSubmit={(values, { setSubmitting }) => {
        const cognitoData = [];

        cognitoData.push(new CognitoUserAttribute({
          Name: 'nickname',
          Value: values.nickname
        }));

        cognito.signUp(values.username, values.password, cognitoData, null, function(err, result){
          if (err) {
              console.log('error', err);
              return;
          }
          var cognitoUser = result.user;
          console.log('user name is ' + cognitoUser.getUsername());
      });
      // A way to set the isSubmitting function in Formik
      // https://jaredpalmer.com/formik/docs/api/formik#issubmitting-boolean
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
            Username
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
          <label>
            Nickname
            <input
              type="text"
              name="nickname"
              onChange={handleChange}
              onBlur={handleBlur}
              value={values.nickname}
            />
            {errors.nickname && touched.nickname && errors.nickname}
          </label>
          <button type="submit" disabled={isSubmitting}>
            Submit
          </button>
        </form>
      )}
    </Formik>
  </div>
);

export default SignUp;
