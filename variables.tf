variable "s3_bucket_name" {
}

variable "s3_transition_to_standard_IA_days" {
  default = 30
}

variable "s3_transition_to_glacier_days" {
  default = 60
}

variable "s3_transition_expiration" {
  default = 61
}

variable "s3_transition_noncurrent_version_expiration" {
  default = 30
}

variable "s3_transition_rule_name" {
  default = "mysql2s3 backup policy"
}

variable "cloudinit_aws_region" {
  default = "us-east-1"
}

variable "cloudinit_aws_s3_queuesize" {
  default = 4
}

variable "cloudinit_aws_s3_partsize" {
  default = "5242880"
}

variable "cloudinit_compression_type" {
  default = "xz"
}

variable "cloudinit_compression_level" {
  default = 2
}

variable "cloudinit_compression_threads" {
  default = 1
}

variable "cloudinit_concurrency" {
  default = 1
}

variable "cloudinit_log_level" {
  default = "debug"
}

variable "cloudinit_mysql_host" {
  default = ""
}

variable "cloudinit_mysql_user" {
  default = ""
}

variable "cloudinit_mysql_pwd" {
  default = ""
}

variable "monitoring_alarm_actions" {
  default = []
}

variable "monitoring_error_actions" {
  default = []
}

variable "monitoring_ok_actions" {
  default = []
}

variable "ec2_enable" {
  default = true
}

variable "ec2_ami" {
  default     = "ami-3709b053"
}

variable "ec2_vpc_security_group_ids" {
  default = []
}

variable "ec2_subnet_id" {
  default = ""
}

variable "ec2_instance_type" {
  default = "t2.small"
}

variable "ec2_tag_name" {
  default = "mysql2s3"
}

variable "ec2_tag_description" {
  default = "Booting this machine will start the entire database backup process and then shutdown."
}

variable "ec2_key_name" {
  default = ""
}

variable "lambda_function_name" {
  default = "mysql2s3"
}


variable "lambda_schedule_is_enabled" {
  default = "true"
}

variable "lambda_schedule_expression" {
  default = "rate(1 day)"
}

