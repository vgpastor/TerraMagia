module "alb" {
  source                         = "git::git@github.com:holaluz/kraken.git//aws/ec2/alb"
  alb_enable_deletion_protection = false
  alb_deregistration_delay       = var.deregistration_delay
  alb_ingress_cidr_blocks        = ["0.0.0.0/0"]
  alb_internal                   = false
  alb_listener_enable_nossl      = false
  alb_tg_hc_path                 = "/health"
  alb_tg_hc_healthy_threshold    = var.target_group_healthy_threshold
  alb_tg_hc_interval             = var.target_group_healthy_interval
  alb_tg_hc_timeout              = var.target_group_healthy_timeout
  alb_tg_type                    = "ip"
  alb_tg_port                    = var.alb_port
  application                    = var.application
  dns_hostname                   = var.dns_hostname
  environment                    = var.environment
  enable_waf                     = true

  providers = {
    aws.main = aws
  }
}

module "ecs_application" {
  source      = "git::git@github.com:holaluz/kraken.git//aws/ecs/ecs_cluster_single_service"
  application = var.application
  container_environment_variables = {
    APP_ENV : var.environment,
    DD_TRACE_CLI_ENABLED : 1,
  }
  container_secrets = {
    DATABASE_URL : "${data.aws_secretsmanager_secret_version.application_config.arn}:database_url::",
  }
  container_port  = var.alb_port
  cpu             = var.cpu
  desired_count   = var.desired_tasks
  environment     = var.environment
  extra_secrets   = var.extra_secrets
  image_tag       = var.environment
  load_balancer   = module.alb.arn_tg
  memory          = var.memory
  repository_url  = "${module.aws_variables.current_account_id}.dkr.ecr.${var.region}.amazonaws.com/solarproduct"
  security_groups = local.security_groups
  datadog_source  = "supervisord"

  providers = {
    aws.main = aws
  }
}

module "infrastructure_dashboard" {
  count = var.environment == "prod" ? 1 : 0

  source = "git::git@github.com:holaluz/kraken.git//datadog/dashboards"

  application         = var.application
  database_name       = var.application
  environment         = var.environment
  github_repository   = "https://github.com/holaluz/solarproduct"
  monitored_resources = ["alb", "ecs", "rds"]
  notion_url          = "https://your-notion-page.com"
  slack_channels      = ["#solar-product-alerts"]
}

module "rds" {
  source                = "git::git@github.com:holaluz/kraken.git//aws/rds/postgresql"
  allocated_storage     = var.allocated_storage
  application           = var.application
  engine_version        = var.engine_version
  environment           = var.environment
  identifier_with_group = false
  kms_enabled           = true
  kms_multi_region      = true
  instance_class        = var.instance_class
  snapshot_identifier_specific = "${local.name}-cypher"
  kms_by_environment = true

  security_groups = compact([
    aws_security_group.this.id,
    module.aws_variables.openvpn_security_group,
    var.environment == "prod" ? var.bi_read_security_group : "",
  ])

  providers = {
    aws.main = aws
  }
}

module "sqs_solarproduct_messenger" {
  source                    = "git::git@github.com:holaluz/kraken.git//aws/sqs"
  application               = var.application
  environment               = var.environment
  queues                    = ["${local.name}-solarproduct_messenger"]
  role                      = module.ecs_application.task_role_name
  message_retention_seconds = 1209600
  dead_letter_queue_name    = "DL-${local.name}-solarproduct_messenger"
  dead_letter_retries       = "10"
  depends_on = [
    module.ecs_application
  ]
}

module "sns_received_services" {
  source              = "git::git@github.com:holaluz/kraken.git//aws/sns/subscription"
  environment         = var.environment
  topic_name          = "antarctica"
  filter_policy_types = ["solar.client_interested"]
  queue_arn           = element(module.sqs_solarproduct_messenger.sqs_queues_arns, 0)
  queue_url           = element(module.sqs_solarproduct_messenger.sqs_queues_urls, 0)
}

module "task_monitor_age_queue" {
  source            = "git::git@github.com:holaluz/kraken.git//datadog/monitors/monitor"
  application       = var.application
  environment       = var.environment
  extra_tags        = ["owner:solarproduct"]
  message           = "Old Messages ${var.application} ${var.environment}! \nNotify: @slack-solar-product-alerts \n"
  renotify_interval = 120
  name              = "[${var.application}-${var.environment}] Old Messages!!"
  query             = "avg(last_5m):avg:aws.sqs.approximate_age_of_oldest_message{application:${var.application},environment:${var.environment}} by {queuename} > 600"
  slack_channels    = ["#solar-product-alerts"]
  tag_resource      = "ecs"
  thresholds = {
    critical = 600
  }
}

module "task_monitor_queue" {
  source            = "git::git@github.com:holaluz/kraken.git//datadog/monitors/monitor"
  application       = var.application
  environment       = var.environment
  extra_tags        = ["owner:solarproduct"]
  message           = "Non consuming Messages ${var.application} ${var.environment}! \nNotify: @slack-solar-product-alerts \n"
  renotify_interval = 120
  name              = "[${var.application}-${var.environment}] Non consuming Messages!!"
  query             = "avg(last_5m):avg:aws.sqs.approximate_number_of_messages_visible{application:${var.application},environment:${var.environment}} by {queuename} > 10"
  slack_channels    = ["#solar-product-alerts"]
  tag_resource      = "ecs"
  thresholds = {
    critical = 10
  }
}