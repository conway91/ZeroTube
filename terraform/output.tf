output "base_url" {
  value = aws_api_gateway_stage.agw_stage.invoke_url
}