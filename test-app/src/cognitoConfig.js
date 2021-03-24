import { CognitoUserPool } from "amazon-cognito-identity-js";
import AWS from "aws-sdk";

export const USER_POOL_ID = "<user pool id>";
export const CLIENT_ID = "<client id>";

AWS.config.update({
  region: "ap-southeast-2",
});

const poolData = {
  UserPoolId: USER_POOL_ID,
  ClientId: CLIENT_ID,
};

const cognito = new CognitoUserPool(poolData);

export const IDENTITY_POOL_ID =
  "ap-southeast-2:7e4339b8-88f3-4be6-ac3d-dd6debe6913d";

export const USER_POOL_URL = `cognito-idp.ap-southeast-2.amazonaws.com/${USER_POOL_ID}`;
export default cognito;
