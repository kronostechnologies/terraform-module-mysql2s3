data "aws_iam_policy_document" "monitoring-s3-policy" {
  statement {
    sid     = "AllowLambdaToListBucket"
    actions = ["s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*",
    ]
  }
}

resource "aws_iam_policy" "monitoring-s3-policy" {
  name   = "${var.lambda_function_name}-monitoring"
  policy = data.aws_iam_policy_document.monitoring-s3-policy.json
}

resource "aws_iam_role_policy_attachment" "monitoring-s3-policy" {
  role       = aws_iam_role.monitoring.name
  policy_arn = aws_iam_policy.monitoring-s3-policy.arn
}

data "aws_iam_policy_document" "monitoring-principals" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "monitoring" {
  name               = "${var.lambda_function_name}-monitoring"
  assume_role_policy = data.aws_iam_policy_document.monitoring-principals.json
}

resource "aws_cloudwatch_event_rule" "monitoring" {
  name                = "${var.lambda_function_name}-monitoring"
  description         = "Launch mysql2s3 monitoring lambda"
  schedule_expression = var.lambda_schedule_expression
}

resource "aws_cloudwatch_event_target" "monitoring" {
  target_id = "${var.lambda_function_name}-monitoring"
  rule      = aws_cloudwatch_event_rule.monitoring.name
  arn       = aws_lambda_function.monitoring.arn
}

resource "aws_lambda_permission" "monitoring" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.monitoring.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.monitoring.arn
}

resource "aws_lambda_function" "monitoring" {
  filename         = "${path.module}/monitoring/dist/mysql2s3-monitoring.zip"
  function_name    = "${var.lambda_function_name}-monitoring"
  role             = aws_iam_role.monitoring.arn
  handler          = "index.handler"
  runtime          = "nodejs12.x"
  timeout          = 3
  source_code_hash = filebase64sha256("${path.module}/monitoring/dist/mysql2s3-monitoring.zip")
  environment {
    variables = {
      BUCKETS = var.s3_bucket_name
    }
  }
}


resource "aws_cloudwatch_metric_alarm" "monitoring-backup-error" {
  alarm_name          = "${var.lambda_function_name}-error"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "86400"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "${var.s3_bucket_name} backup error"
  treat_missing_data  = "missing"
  dimensions = {
    FunctionName = "${var.lambda_function_name}-monitoring"
  }
  alarm_actions             = var.monitoring_alarm_actions
  insufficient_data_actions = var.monitoring_error_actions
  ok_actions                = var.monitoring_ok_actions
}
