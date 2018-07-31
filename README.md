# Terraform Module Mysql2s3

This terraform module creates a lambda function that launches an ec2 machine which launch [mysql2s3 docker container](https://github.com/kronostechnologies/docker-mysql2s3).

## Usage

```
locals {
  bucket_name = "mysql2s3-bucket-name"
  lambda_name = "mysql2s3-lambda-name"
}

# SECURITY GROUPS
resource "aws_security_group" "mysql2s3-lambda" {
  name        = "mysql2s3-lambda"
  description = "mysql2s3-lambda"

  # if you need ssh access for debugging the ec2 that starts the backup procedure
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # access for mysql port
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # access for apt and docker pull
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Actual module
module "backup" {
  source = "github.com/kronostechnologies/terraform-module-mysql2s3"
  s3_bucket_name = "mybucketname"
  s3_transition_to_standard_IA_days = 30
  s3_transition_to_glacier_days = 60
  s3_transition_expiration = 61
  s3_transition_noncurrent_version_expiration = 30
  s3_transition_rule_name = "mysql2s3 backup policy"
  cloudinit_aws_region = "us-east-1"
  cloudinit_aws_s3_queuesize = 4
  cloudinit_aws_s3_partsize = "5242880"
  cloudinit_compression_type = "xz"
  cloudinit_compression_level = 2
  cloudinit_compression_threads = 1
  cloudinit_concurrency = 1
  cloudinit_log_level = "debug"
  cloudinit_mysql_host = "my_mysql_host.com"
  cloudinit_mysql_user = "user"
  cloudinit_mysql_pwd = "password"
  ec2_ami = "ami-3709b053"
  ec2_vpc_security_group_ids = ["${aws_security_group.mysql2s3-lambda.id}"]
  ec2_subnet_id = "subnet-id-here"
  ec2_instance_type = "t2.small"
  ec2_tag_name = "mysql2s3"
  ec2_tag_description = "Booting this machine will start the entire database backup process and then shutdown."
  ec2_key_name = "your-keyname"
  lambda_function_name = "${local.lambda_name}"
  lambda_schedule_expression = "rate(1 day)"
}
```

> Variables prefixed with "cloudinit" are variables passed to the docker container. See [mysql2s3 docker container](https://github.com/kronostechnologies/docker-mysql2s3).

## CloudWatch Alarm

If you need cloud watch alarm, add this next to the module definition. This alarm will change to ALARM state whenever there is 1 error within 1 day with the lambda invocation.

```
resource "aws_cloudwatch_metric_alarm" "mnysql2s3-lambda-error" {
  alarm_name                = "${local.lambda_name}-error"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "Errors"
  namespace                 = "AWS/Lambda"
  period                    = "86400" # 1 day period
  statistic                 = "Average"
  threshold                 = "1"
  alarm_description         = "This metric monitors error with lambda function '${local.lambda_name}'"
  dimensions {
    FunctionName = "${local.lambda_name}"
  }
  alarm_actions             = ["ARN TOPIC"]
}
```

Depending on module configuration, you may want to change the period. If you run the backup process every 6 hours, you want the period to be 21600 seconds (6 hours).

If you run the backup process once a week, you will want to consider missing data as good data. Add `treat_missing_data = notBreaching` because you cannot set a period to more than 1 day.
