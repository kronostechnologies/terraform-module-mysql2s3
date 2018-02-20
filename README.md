# Terraform Module Mysql2s3

This terraform module creates a lambda function that launches an ec2 machine which launch [mysql2s3 docker container](https://github.com/kronostechnologies/docker-mysql2s3).

## Usage

```
resource "aws_security_group" "mysql2s3-lambda" {
  name        = "mysql2s3-lambda"
  description = "mysql2s3-lambda"

  # if you need ssh access for debugging
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

module "backup" {
  source = "github.com/kronostechnologies/terraform-module-mysql2s3"
  s3_bucket_name = "mybucketname"
  s3_transition_to_standard_IA_days = 30
  s3_transition_to_glacier_days = 60
  s3_transition_expiration = 61
  s3_transition_noncurrent_version_expiration = 30
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
  lambda_function_name = "mysql2s3"
  lambda_schedule_expression = "rate(1 day)"
}
```

> Variables prefixed with "cloudinit" are variables passed to the docker container. See [mysql2s3 docker container](https://github.com/kronostechnologies/docker-mysql2s3).

