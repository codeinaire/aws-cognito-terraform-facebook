provider "aws" {
  region = "ap-southeast-2"
}

provider "archive" {}

variable "region" {
  default = "ap-southeast-2"
}

variable "account_id" {
  default = "<account id goes here>"
}

# this part of the aws tute is here - https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pool-as-user-directory.html
resource "aws_cognito_user_pool" "test_app" {
  # These are grouped according to the pages on the console
  name = "test-app"

  # Attributes
  alias_attributes = ["email", "preferred_username"]

  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "nickname"
    required            = true
  }

  # Policies - we can set the admin to create a user, but that requires a backend auth process
  # look up best practice for password creation
  password_policy {
    minimum_length    = "8"
    require_lowercase = false
    require_numbers   = false
    require_symbols   = false
    require_uppercase = false
  }

  # MFA and verifications
  mfa_configuration        = "OFF"
  auto_verified_attributes = ["email"]

  # Message customizations
  verification_message_template {
    default_email_option  = "CONFIRM_WITH_LINK"
    email_message_by_link = "Your life will be dramatically improved by signing up. {##Click Here##}"
    email_subject_by_link = "Welcome to to a new world and life"
  }
  # Best practice is to use Amazon SES in Production due to daily email limit
  email_configuration {
    reply_to_email_address = "a-email-for-people-to@reply.to"
  }
  # SMS requires the use of Amazon SNS

  # Tags
  tags = {
    project = "Test App"
  }

  # Devices
  # may remove this as it could be annoying to the user
  device_configuration {
    challenge_required_on_new_device      = true
    device_only_remembered_on_user_prompt = true
  }
}

# * N.B. This is required when using CONFIRM_WITH_LINK b/c it needs a domain name
# * for the page used to confirm a user with the email link
# Domain name
resource "aws_cognito_user_pool_domain" "test_app" {
  user_pool_id = "${aws_cognito_user_pool.test_app.id}"
  # Domain prefix
  domain = "test-app-123451"
}

# This part of the AWS tute is here https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pools-configuring-app-integration.html
resource "aws_cognito_user_pool_client" "test_app" {
  user_pool_id = "${aws_cognito_user_pool.test_app.id}"

  # App clients
  name                   = "test-app-client"
  refresh_token_validity = 30
  read_attributes  = ["nickname"]
  write_attributes = ["nickname"]

  # App integration -
  # App client settings
  supported_identity_providers = ["COGNITO"]

  callback_urls                = ["http://localhost:3000/"]
  logout_urls                  = ["http://localhost:3000/"]
}

#  !___ COGNITO IDENTITY POOL ___ #
# aws docs for IDENTITY POOLS RESOURCE https://docs.aws.amazon.com/cognito/latest/developerguide/getting-started-with-identity-pools.html
resource "aws_cognito_identity_pool" "test_app_id_pool" {
  identity_pool_name               = "test app"
  allow_unauthenticated_identities = false
  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.test_app.id
    provider_name           = aws_cognito_user_pool.test_app.endpoint
    server_side_token_check = false
  }

  supported_login_providers = {
    "graph.facebook.com" = "<your App ID goes here. Refer to picture at the top>"
  }
}

resource "aws_cognito_identity_pool_roles_attachment" "test_app_id_roles" {
  identity_pool_id = aws_cognito_identity_pool.test_app_id_pool.id

  roles = {
    "authenticated"   = aws_iam_role.api_gateway_access.arn
    "unauthenticated" = aws_iam_role.deny_everything.arn
  }
}

resource "aws_iam_role_policy" "api_gateway_access" {
  name   = "api-gateway-access"
  role   = aws_iam_role.api_gateway_access.id
  policy = data.aws_iam_policy_document.api_gateway_access.json
}

resource "aws_iam_role" "api_gateway_access" {
  name = "ap-gateway-access"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.test_app_id_pool.id}"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "authenticated"
        }
      }
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "api_gateway_access" {
  version = "2012-10-17"
  statement {
    actions = [
      "execute-api:Invoke"
    ]

    effect = "Allow"

    resources = ["arn:aws:execute-api:*:*:*"]
  }
}

resource "aws_iam_role_policy" "deny_everything" {
  name   = "deny_everything"
  role   = aws_iam_role.deny_everything.id
  policy = data.aws_iam_policy_document.deny_everything.json
}

resource "aws_iam_role" "deny_everything" {
  name = "deny_everything"
  # This will grant the role the ability for cognito identity to assume it
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.test_app_id_pool.id}"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "unauthenticated"
        }
      }
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "deny_everything" {
  version = "2012-10-17"

  statement {
    actions = ["*"]
    effect    = "Deny"
    resources = ["*"]
  }
}

#  !___ LAMBDA FUNCTION ___ #
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "./testLambda"
  output_path = "lambda.zip"
}

resource "aws_lambda_function" "example_test_function" {
  filename         = "${data.archive_file.lambda.output_path}"
  function_name    = "example_test_function"
  role             = "${aws_iam_role.example_api_role.arn}"
  handler          = "index.handler"
  runtime          = "nodejs10.x"
  source_code_hash = "${filebase64sha256("${data.archive_file.lambda.output_path}")}"
  publish          = true
}

resource "aws_iam_role" "example_api_role" {
  name               = "example_api_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  version = "2012-10-17"
  # ASSUME ROLE
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.example_test_function.function_name}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.example_api.id}/*/${aws_api_gateway_method.example_api_method.http_method}${aws_api_gateway_resource.example_api_resource.path}"
}

# !___ API GATEWAY ___ #
resource "aws_api_gateway_rest_api" "example_api" {
  name        = "Secure API Gateway"
  description = "Example Rest Api"
}

resource "aws_api_gateway_resource" "example_api_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.example_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.example_api.root_resource_id}"
  path_part   = "test"
}

resource "aws_api_gateway_method" "example_api_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.example_api.id}"
  resource_id   = "${aws_api_gateway_resource.example_api_resource.id}"
  http_method   = "POST"
  authorization = "AWS_IAM"

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "example_api_method-integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.example_api.id}"
  resource_id             = "${aws_api_gateway_resource.example_api_resource.id}"
  http_method             = "${aws_api_gateway_method.example_api_method.http_method}"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${aws_lambda_function.example_test_function.function_name}/invocations"
  integration_http_method = "POST"
}

resource "aws_api_gateway_deployment" "example_deployment_dev" {
  depends_on = [
    "aws_api_gateway_method.example_api_method",
    "aws_api_gateway_integration.example_api_method-integration"
  ]
  rest_api_id = "${aws_api_gateway_rest_api.example_api.id}"
  stage_name  = "dev"
}


output "user_pool_id" {
  value = aws_cognito_user_pool.test_app.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.test_app.id
}

output "identity_pool_id" {
  value = aws_cognito_identity_pool.test_app_id_pool.id
}

output "test_app_url" {
  value = "https://${aws_api_gateway_deployment.example_deployment_dev.rest_api_id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_deployment.example_deployment_dev.stage_name}"
}