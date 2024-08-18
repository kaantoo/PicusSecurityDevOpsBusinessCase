provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_policy"
  role   = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:us-east-1:888577048636:table/TestDB"
      },
    ]
  })
}

resource "aws_lambda_function" "delete_item" {
  function_name = "deleteItem"
  handler       = "LambdaDelete.lambda_handler"
  runtime       = "python3.8"
  role          = aws_iam_role.lambda_role.arn

  filename      = "${path.module}/lambda_function.zip"

  environment {
    variables = {
      TABLE_NAME = "TestDB"
    }
  }
}

resource "aws_api_gateway_rest_api" "picus_api" {
  name        = "picus-api"
  description = "API for Picus Service"
}

resource "aws_api_gateway_resource" "picus_resource" {
  rest_api_id = aws_api_gateway_rest_api.picus_api.id
  parent_id   = aws_api_gateway_rest_api.picus_api.root_resource_id
  path_part   = "picus"
}

resource "aws_api_gateway_resource" "key_resource" {
  rest_api_id = aws_api_gateway_rest_api.picus_api.id
  parent_id   = aws_api_gateway_resource.picus_resource.id
  path_part   = "{key}"
}

resource "aws_api_gateway_method" "delete_method" {
  rest_api_id   = aws_api_gateway_rest_api.picus_api.id
  resource_id   = aws_api_gateway_resource.key_resource.id
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "delete_integration" {
  rest_api_id = aws_api_gateway_rest_api.picus_api.id
  resource_id = aws_api_gateway_resource.key_resource.id
  http_method = aws_api_gateway_method.delete_method.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.delete_item.invoke_arn
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_item.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.picus_api.execution_arn}/*/*"
}

output "api_url" {
  value = "${aws_api_gateway_rest_api.picus_api.execution_arn}/picus/{key}"
}