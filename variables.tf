variable "s3_bucket_name" {}

variable "cloudinit_aws_region" { default = "us-east-1" }
variable "cloudinit_aws_access_key_id" {}
variable "cloudinit_aws_secret_access_key" {}
variable "cloudinit_aws_s3_queuesize" { default = 4 }
variable "cloudinit_aws_s3_partsize" { default = "5242880" }
variable "cloudinit_compression_type" { default = "xz" }
variable "cloudinit_compression_level" { default = 2 }
variable "cloudinit_compression_threads" { default = 1 }
variable "cloudinit_concurrency" { default = 1 }
variable "cloudinit_keyname_template" { default = "UTC:yyyy'/'mm'/'dd'/$database.sql.xz'" }
variable "cloudinit_log_level" { default = "debug" }
variable "cloudinit_mysql_host" {}
variable "cloudinit_mysql_user" {}
variable "cloudinit_mysql_pwd" {}

variable "ec2_ami" { default = "ami-3709b053" description = "The default AMI 'ami-3709b053' is a debian stretch" }
variable "ec2_vpc_security_group_ids" { type = "list" }
variable "ec2_subnet_id" {}
variable "ec2_instance_type" { default = "t2.small" }
variable "ec2_tag_name" { default = "mysql2s3" }
variable "ec2_tag_description" { default = "Booting this machine will start the entire database backup process." }
variable "ec2_key_name" {}

variable "lambda_schedule_expression" { default = "rate(1 day)" }