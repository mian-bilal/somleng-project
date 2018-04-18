locals {
  is_web_tier = "${var.tier == "WebServer" ? "true" : "false"}"

  # Workaround for worker tier
  default_namespace = "aws:elasticbeanstalk:application:environment"
  default_env_name  = "UNUSED_ENV_VAR"
}

resource "aws_elastic_beanstalk_environment" "eb_env" {
  name                = "${var.env_identifier}-${lower(var.tier)}"
  application         = "${var.app_name}"
  tier                = "${var.tier}"
  solution_stack_name = "${var.solution_stack_name}"

  ################### VPC ###################
  # https://amzn.to/2JzNUcK
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = "${var.vpc_id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${join(",", var.private_subnets)}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${join(",", var.public_subnets)}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "false"
  }


  ################### EC2 Settings ###################
  # http://amzn.to/2FjIpj6
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = "${join(",", var.security_groups)}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "${var.instance_type}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "${var.ec2_instance_role}"
  }

  ################### Code Deployment Settings ###################
  # http://amzn.to/2thpK2U
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "DeploymentPolicy"
    value     = "AllAtOnce"
  }

  ################### Rolling Updates ###################
  # http://amzn.to/2oMEP78
  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateType"
    value     = "Time"
  }

  ################### Health Reporting ###################
  # http://amzn.to/2FbOMlh
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  ################### Managed Updates ###################
  # http://amzn.to/2tcRsOe
  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "ManagedActionsEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "PreferredStartTime"
    value     = "Sun:19:00"
  }

  ################### Managed Platform Updates ###################
  # http://amzn.to/2tccGLY
  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name      = "InstanceRefreshEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name      = "UpdateLevel"
    value     = "minor"
  }

  ################### CloudWatch Logs ###################
  # https://amzn.to/2uNOMYb
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "${var.cloudwatch_enabled}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "DeleteOnTerminate"
    value     = "${var.cloudwatch_delete_on_terminate}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = "${var.cloudwatch_retention_in_days}"
  }

  ################### Default Process ###################
  # https://amzn.to/2HcmWaG
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Port"
    value     = "80"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Protocol"
    value     = "HTTP"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/health_checks"
  }

  ################### EB Environment ###################
  # https://amzn.to/2FR9RTu
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = "${var.service_role}"
  }

  setting {
    namespace = "${local.is_web_tier ? "aws:elasticbeanstalk:environment" : local.default_namespace}"
    name      = "${local.is_web_tier ? "LoadBalancerType" : local.default_env_name}"
    value     = "${local.is_web_tier ? "application" : ""}"
  }

  ################### Listener ###################
  # https://amzn.to/2GzHQiB
  setting {
    namespace = "${local.is_web_tier ? "aws:elbv2:listener:default" : local.default_namespace}"
    name      = "${local.is_web_tier ? "ListenerEnabled" : local.default_env_name}"
    value     = "${local.is_web_tier ? "true" : ""}"
  }
  setting {
    namespace = "${local.is_web_tier ? "aws:elbv2:listener:443" : local.default_namespace}"
    name      = "${local.is_web_tier ? "ListenerEnabled" : local.default_env_name}"
    value     = "${local.is_web_tier ? "true" : ""}"
  }
  setting {
    namespace = "${local.is_web_tier ? "aws:elbv2:listener:443" : local.default_namespace}"
    name      = "${local.is_web_tier ? "Protocol" : local.default_env_name}"
    value     = "${local.is_web_tier ? "HTTPS" : ""}"
  }
  setting {
    namespace = "${local.is_web_tier ? "aws:elbv2:listener:443" : local.default_namespace}"
    name      = "${local.is_web_tier ? "SSLCertificateArns" : local.default_env_name}"
    value     = "${local.is_web_tier ? var.ssl_certificate_id : ""}"
  }
  # Security Policies
  # https://amzn.to/2q742us
  setting {
    namespace = "${local.is_web_tier ? "aws:elbv2:listener:443" : local.default_namespace}"
    name      = "${local.is_web_tier ? "SSLPolicy" : local.default_env_name}"
    value     = "${local.is_web_tier ? "ELBSecurityPolicy-TLS-1-1-2017-01" : ""}"
  }

  ################### ENV Vars ###################
  # https://amzn.to/2Ez6CgW
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RAILS_SKIP_ASSET_COMPILATION"
    value     = "${var.rails_skip_asset_compilation}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "EB_TIER"
    value     = "${var.tier}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PROCESS_ACTIVE_ELASTIC_JOBS"
    value     = "${var.process_active_elastic_jobs}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATABASE_URL"
    value     = "${var.database_url}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RAILS_MASTER_KEY"
    value     = "${var.rails_master_key}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_REGION"
    value     = "${var.aws_region}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RACK_ENV"
    value     = "${var.rails_env}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RAILS_ENV"
    value     = "${var.rails_env}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DEFAULT_URL_HOST"
    value     = "${var.default_url_host}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_POOL"
    value     = "${var.db_pool}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DEFAULT_QUEUE_URL"
    value     = "${var.default_queue_url}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_SNS_MESSAGE_PROCESSOR_JOB_QUEUE_URL"
    value     = "${var.aws_sns_message_processor_job_queue_url}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "CALL_DATA_RECORD_JOB_QUEUE_URL"
    value     = "${var.call_data_record_job_queue_url}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "OUTBOUND_CALL_JOB_QUEUE_URL"
    value     = "${var.outbound_call_job_queue_url}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RECORDING_PROCESSOR_JOB_QUEUE_URL"
    value     = "${var.recording_processor_job_queue_url}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RECORDING_STATUS_CALLBACK_NOTIFIER_JOB_QUEUE_URL"
    value     = "${var.recording_status_callback_notifier_job_queue_url}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "STATUS_CALLBACK_NOTIFIER_JOB_QUEUE_URL"
    value     = "${var.status_callback_notifier_job_queue_url}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_S3_ACCESS_KEY_ID"
    value     = "${var.s3_access_key_id}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_S3_SECRET_ACCESS_KEY"
    value     = "${var.s3_secret_access_key}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "UPLOADS_BUCKET"
    value     = "${var.uploads_bucket}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "OUTBOUND_CALL_DRB_URI"
    value     = "${var.outbound_call_drb_uri}"
  }
}
