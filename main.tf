# User access
resource "aws_iam_user" "backup" {
  name          = "mysql2s3-${var.s3_bucket_name}"
  path          = "/"
  force_destroy = true
}

resource "aws_iam_user_policy" "backup" {
  name   = "mysql2s3-${var.s3_bucket_name}"
  policy = "${data.aws_iam_policy_document.backup.json}"
  user   = "${aws_iam_user.backup.name}"
}

resource "aws_iam_access_key" "backup" {
  user = "${aws_iam_user.backup.name}"
}

data "aws_iam_policy_document" "backup" {
  statement {
    actions   = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*",
    ]
  }
}

# Bucket definition
resource "aws_s3_bucket" "backup" {
  bucket = "${var.s3_bucket_name}"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id = "5-year backup policy"
    enabled = true
    prefix = ""
    abort_incomplete_multipart_upload_days = 1

    transition {
      days = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 91
    }

    noncurrent_version_expiration {
      days = 1736
    }
  }

  tags {
    Name = "${var.s3_bucket_name}"
  }
}

# EC2 Cloud-init
data "template_cloudinit_config" "instance" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = "${file("${path.module}/cloudinit.yaml")}"
  }
}

data "template_file" "cloudinit" {
  count = 1
  template = "${data.template_cloudinit_config.instance.rendered}"
  vars {
    fqdn = "mysql2s3"
    aws_region = "${var.cloudinit_aws_region}"
    aws_access_key_id = "${aws_iam_access_key.backup.id}"
    aws_secret_access_key = "${aws_iam_access_key.backup.secret}"
    aws_s3_bucket = "${var.s3_bucket_name}"
    aws_s3_queuesize = "${var.cloudinit_aws_s3_queuesize}"
    aws_s3_partsize = "${var.cloudinit_aws_s3_partsize}"
    compression_type = "${var.cloudinit_compression_type}"
    compression_level = "${var.cloudinit_compression_level}"
    compression_threads = "${var.cloudinit_compression_threads}"
    concurrency = "${var.cloudinit_concurrency}"
    keyname_template = "${var.cloudinit_keyname_template}"
    log_level = "${var.cloudinit_log_level}"
    mysql_host = "${var.cloudinit_mysql_host}"
    mysql_user = "${var.cloudinit_mysql_user}"
    mysql_pwd = "${var.cloudinit_mysql_pwd}"
  }
}

# EC2 machine
resource "aws_instance" "instance" {
  ami = "${var.ec2_ami}"
  instance_type = "${var.ec2_instance_type}"
  vpc_security_group_ids = [ "${var.ec2_vpc_security_group_ids}" ]
  subnet_id = "${var.ec2_subnet_id}"
  user_data = "${element(data.template_file.cloudinit.*.rendered, 1)}"
  key_name = "${var.ec2_key_name}"
  root_block_device {
    delete_on_termination = true
    volume_size = "8"
    volume_type = "standard"
  }
  tags {
    "Name" = "${var.ec2_tag_name}"
    "Description" = "${var.ec2_tag_description}"
    "LambdaName" = "${var.s3_bucket_name}"
  }
}

# Scheduled Lambda
data "aws_iam_policy_document" "lambda" {
  statement {
    sid = "1"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ec2:StartInstances",
      "ec2:GetConsoleOutput",
    ]

    resources = [
      "*",
    ]
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/backup.py"
  output_path = "${path.module}/backup.zip"
}

resource "aws_iam_role" "lambda" {
  name = "mysql2s3-${var.s3_bucket_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda" {
  name = "mysql2s3-${var.s3_bucket_name}"
  role = "${aws_iam_role.lambda.name}"

  policy = "${data.aws_iam_policy_document.lambda.json}"
}

resource "aws_lambda_function" "lambda" {
  runtime          = "python2.7"
  filename         = "${path.module}/backup.zip"
  function_name    = "${var.lambda_function_name}"
  role             = "${aws_iam_role.lambda.arn}"
  handler          = "backup.lambda_handler"
  source_code_hash = "${data.archive_file.lambda.output_base64sha256}"
  timeout          = 3
  environment {
    variables = {
      LAMBDA_EC2_ID = "${aws_instance.instance.id}"
    }
  }
}

resource "aws_lambda_permission" "cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.arn}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.lambda.arn}"
}

resource "aws_cloudwatch_event_rule" "lambda" {
  name                = "mysql2s3-${var.s3_bucket_name}-${aws_instance.instance.id}"
  schedule_expression = "${var.lambda_schedule_expression}"
}

resource "aws_cloudwatch_event_target" "lambda" {
  target_id = "mysql2s3-${var.s3_bucket_name}-${aws_instance.instance.id}"
  rule      = "${aws_cloudwatch_event_rule.lambda.name}"
  arn       = "${aws_lambda_function.lambda.arn}"
}