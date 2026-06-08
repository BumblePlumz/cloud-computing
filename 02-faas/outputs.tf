output "function_name" {
  description = "Nom de la fonction Lambda"
  value       = aws_lambda_function.api.function_name
}

output "api_id" {
  description = "ID de l'API Gateway REST"
  value       = aws_api_gateway_rest_api.api.id
}

output "users_table" {
  description = "Table DynamoDB servie par l'API"
  value       = aws_dynamodb_table.users.name
}

# URL d'invocation (convention LocalStack : .../_user_request_/<path>)
output "invoke_url" {
  description = "URL de base de l'API (ajouter /hello, /users, ...)"
  value       = "http://localhost:4566/restapis/${aws_api_gateway_rest_api.api.id}/${aws_api_gateway_stage.dev.stage_name}/_user_request_"
}
