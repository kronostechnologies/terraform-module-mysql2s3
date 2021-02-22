output "aws_access_key_id" {
  value = var.iam_enable ? aws_iam_access_key.backup[0].id : ""
}

output "aws_secret_access_key" {
  value = var.iam_enable ? aws_iam_access_key.backup[0].secret : ""
}