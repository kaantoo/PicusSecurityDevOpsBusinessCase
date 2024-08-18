output "lambda_function_arn" {
  value = aws_lambda_function.delete_item.arn
}

output "api_gateway_url" {
  value = aws_api_gateway_rest_api.picus_api.execution_arn
}