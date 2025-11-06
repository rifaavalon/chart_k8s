terraform {
  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.0"
    }
  }
}

resource "datadog_monitor" "high_cpu" {
  name    = "[${var.environment}] High CPU Usage"
  type    = "metric alert"
  message = <<-EOT
    CPU usage is above 80% on {{host.name}}

    Environment: ${var.environment}

    @slack-datadog-alerts
    {{#is_alert}}
    Alert: CPU usage is critically high!
    {{/is_alert}}
    {{#is_warning}}
    Warning: CPU usage is elevated
    {{/is_warning}}
  EOT

  query = "avg(last_5m):avg:system.cpu.user{env:${var.environment}} by {host} > 80"

  monitor_thresholds {
    critical = 80
    warning  = 70
  }

  notify_no_data    = true
  no_data_timeframe = 10
  renotify_interval = 60

  tags = [
    "env:${var.environment}",
    "service:infrastructure",
    "team:platform"
  ]
}

resource "datadog_monitor" "high_memory" {
  name    = "[${var.environment}] High Memory Usage"
  type    = "metric alert"
  message = <<-EOT
    Memory usage is above 85% on {{host.name}}

    Environment: ${var.environment}
    Current value: {{value}}%

    @slack-datadog-alerts
  EOT

  query = "avg(last_5m):avg:system.mem.pct_usable{env:${var.environment}} by {host} < 15"

  monitor_thresholds {
    critical = 15  # Less than 15% available = critical
    warning  = 25  # Less than 25% available = warning
  }

  notify_no_data    = true
  no_data_timeframe = 10

  tags = [
    "env:${var.environment}",
    "service:infrastructure",
    "team:platform"
  ]
}

resource "datadog_monitor" "high_disk" {
  name    = "[${var.environment}] High Disk Usage"
  type    = "metric alert"
  message = <<-EOT
    Disk usage is above 85% on {{host.name}}

    Environment: ${var.environment}
    Device: {{device}}
    Current usage: {{value}}%

    Action required: Review disk usage and clean up if needed

    @slack-datadog-alerts
    @pagerduty-infrastructure
  EOT

  query = "avg(last_5m):avg:system.disk.in_use{env:${var.environment}} by {host,device} > 0.85"

  monitor_thresholds {
    critical = 0.85  # 85%
    warning  = 0.75  # 75%
  }

  notify_no_data    = true
  no_data_timeframe = 20

  tags = [
    "env:${var.environment}",
    "service:infrastructure",
    "team:platform"
  ]
}

resource "datadog_monitor" "apache_down" {
  name    = "[${var.environment}] Apache Service Down"
  type    = "service check"
  message = <<-EOT
    Apache is not responding on {{host.name}}

    Environment: ${var.environment}

    Immediate action required!

    @slack-datadog-alerts
    @pagerduty-critical
  EOT

  query = "\"apache.can_connect\".over(\"env:${var.environment}\").by(\"host\").last(2).count_by_status()"

  monitor_thresholds {
    critical = 1
    warning  = 1
    ok       = 1
  }

  notify_no_data    = true
  no_data_timeframe = 5
  renotify_interval = 0  # Don't renotify for service checks

  tags = [
    "env:${var.environment}",
    "service:apache",
    "team:platform"
  ]
}

resource "datadog_monitor" "host_unreachable" {
  name    = "[${var.environment}] Host Unreachable"
  type    = "service check"
  message = <<-EOT
    Datadog agent is not reporting from {{host.name}}

    Environment: ${var.environment}

    Possible causes:
    - Agent stopped
    - Network connectivity issue
    - Host down

    @slack-datadog-alerts
    @pagerduty-critical
  EOT

  query = "\"datadog.agent.up\".over(\"env:${var.environment}\").by(\"host\").last(2).count_by_status()"

  monitor_thresholds {
    critical = 1
    ok       = 1
  }

  notify_no_data    = true
  no_data_timeframe = 3
  require_full_window = false

  tags = [
    "env:${var.environment}",
    "service:infrastructure",
    "team:platform",
    "priority:critical"
  ]
}

resource "datadog_monitor" "http_errors" {
  name    = "[${var.environment}] High HTTP Error Rate"
  type    = "metric alert"
  message = <<-EOT
    HTTP error rate (5xx) is elevated on {{host.name}}

    Environment: ${var.environment}
    Current rate: {{value}} errors/min

    Check Apache logs: sudo tail -f /var/log/httpd/error_log

    @slack-datadog-alerts
  EOT

  query = "avg(last_5m):sum:apache.net.hits{env:${var.environment},response_code:5*} by {host}.as_rate() > 10"

  monitor_thresholds {
    critical = 10  # 10 errors/min
    warning  = 5   # 5 errors/min
  }

  notify_no_data    = false

  tags = [
    "env:${var.environment}",
    "service:apache",
    "team:platform"
  ]
}

resource "datadog_monitor" "request_anomaly" {
  name    = "[${var.environment}] Unusual Request Rate"
  type    = "query alert"
  message = <<-EOT
    Unusual request rate detected on {{host.name}}

    Environment: ${var.environment}

    This could indicate:
    - Traffic spike (good or bad)
    - DDoS attack
    - Bot activity

    Review traffic patterns and investigate

    @slack-datadog-alerts
  EOT

  query = "avg(last_1h):anomalies(avg:apache.net.hits{env:${var.environment}} by {host}.as_rate(), 'basic', 2, direction='both', interval=60, alert_window='last_15m', count_default_zero='true') >= 1"

  monitor_thresholds {
    critical          = 1
    critical_recovery = 0
  }

  notify_no_data = false

  tags = [
    "env:${var.environment}",
    "service:apache",
    "team:platform",
    "type:anomaly"
  ]
}

resource "datadog_monitor" "host_critical" {
  name    = "[${var.environment}] Host Critical - Multiple Issues"
  type    = "composite"
  message = <<-EOT
    Multiple critical issues detected on a host in ${var.environment}

    This indicates a severely degraded host that may need immediate attention.

    Actions:
    1. Check host health in Datadog
    2. Review system logs
    3. Consider failing over traffic
    4. Prepare for possible host replacement

    @slack-datadog-alerts
    @pagerduty-critical
  EOT

  query = "${datadog_monitor.high_cpu.id} && ${datadog_monitor.high_memory.id}"

  tags = [
    "env:${var.environment}",
    "service:infrastructure",
    "team:platform",
    "priority:critical",
    "type:composite"
  ]
}

resource "datadog_dashboard" "infrastructure" {
  title       = "[${var.environment}] Infrastructure Overview"
  description = "Infrastructure monitoring dashboard for ${var.environment} environment"
  layout_type = "ordered"

  widget {
    group_definition {
      title       = "Host Health"
      layout_type = "ordered"

      widget {
        hostmap_definition {
          title       = "Host CPU Usage"
          request {
            fill {
              q = "avg:system.cpu.user{env:${var.environment}} by {host}"
            }
          }
          node_type = "host"
          no_group_hosts = false
          no_metric_hosts = false
          style {
            palette      = "green_to_orange"
            palette_flip = false
          }
        }
      }

      widget {
        timeseries_definition {
          title = "CPU Usage by Host"
          request {
            q            = "avg:system.cpu.user{env:${var.environment}} by {host}"
            display_type = "line"
          }
          yaxis {
            scale = "linear"
            min   = "0"
            max   = "100"
          }
        }
      }

      widget {
        timeseries_definition {
          title = "Memory Usage by Host"
          request {
            q            = "avg:system.mem.pct_usable{env:${var.environment}} by {host}"
            display_type = "line"
          }
          yaxis {
            scale = "linear"
            min   = "0"
            max   = "100"
          }
        }
      }
    }
  }

  widget {
    group_definition {
      title       = "Apache Performance"
      layout_type = "ordered"

      widget {
        query_value_definition {
          title       = "Total Requests/min"
          title_size  = "16"
          title_align = "left"
          request {
            q          = "sum:apache.net.hits{env:${var.environment}}.as_rate()"
            aggregator = "avg"
          }
          autoscale = true
          precision = 2
        }
      }

      widget {
        timeseries_definition {
          title = "HTTP Requests by Response Code"
          request {
            q            = "sum:apache.net.hits{env:${var.environment}} by {response_code}.as_rate()"
            display_type = "bars"
          }
        }
      }

      widget {
        timeseries_definition {
          title = "Apache Request Rate by Host"
          request {
            q            = "sum:apache.net.hits{env:${var.environment}} by {host}.as_rate()"
            display_type = "line"
          }
        }
      }
    }
  }

  widget {
    group_definition {
      title       = "System Resources"
      layout_type = "ordered"

      widget {
        timeseries_definition {
          title = "Disk Usage"
          request {
            q            = "avg:system.disk.in_use{env:${var.environment}} by {host,device}"
            display_type = "line"
          }
          yaxis {
            scale = "linear"
            min   = "0"
            max   = "1"
          }
        }
      }

      widget {
        timeseries_definition {
          title = "Network Traffic"
          request {
            q            = "avg:system.net.bytes_rcvd{env:${var.environment}} by {host}"
            display_type = "area"
          }
          request {
            q            = "avg:system.net.bytes_sent{env:${var.environment}} by {host}"
            display_type = "area"
          }
        }
      }
    }
  }

  widget {
    note_definition {
      content          = "## Infrastructure Dashboard\n\nThis dashboard shows key metrics for the ${var.environment} environment.\n\n**Quick Links:**\n- [Host Map](https://app.datadoghq.com/infrastructure/map)\n- [Logs](https://app.datadoghq.com/logs)\n- [APM](https://app.datadoghq.com/apm/home)"
      background_color = "blue"
      font_size        = "14"
      text_align       = "left"
      show_tick        = false
      tick_pos         = "50%"
      tick_edge        = "left"
    }
  }
}

resource "datadog_service_level_objective" "availability" {
  name        = "[${var.environment}] Service Availability"
  type        = "monitor"
  description = "Tracks uptime of hosts in ${var.environment}"

  monitor_ids = [
    datadog_monitor.host_unreachable.id,
    datadog_monitor.apache_down.id
  ]

  thresholds {
    timeframe = "7d"
    target    = 99.9
    warning   = 99.95
  }

  thresholds {
    timeframe = "30d"
    target    = 99.5
    warning   = 99.9
  }

  tags = [
    "env:${var.environment}",
    "service:infrastructure",
    "team:platform"
  ]
}

# ECS Monitors
resource "datadog_monitor" "ecs_cpu_high" {
  count = var.enable_ecs_monitoring ? 1 : 0

  name    = "[${var.environment}] ECS Task CPU High"
  type    = "metric alert"
  message = <<-EOT
    ECS task CPU is above 80% in ${var.environment}

    Service: {{ecs_service_name.name}}
    Task: {{ecs_task_family.name}}

    @slack-datadog-alerts
  EOT

  query = "avg(last_5m):avg:ecs.fargate.cpu.percent{env:${var.environment}} by {ecs_service_name,ecs_task_family} > 80"

  monitor_thresholds {
    critical = 80
    warning  = 70
  }

  notify_no_data = false

  tags = [
    "env:${var.environment}",
    "service:ecs",
    "team:platform"
  ]
}

resource "datadog_monitor" "ecs_memory_high" {
  count = var.enable_ecs_monitoring ? 1 : 0

  name    = "[${var.environment}] ECS Task Memory High"
  type    = "metric alert"
  message = <<-EOT
    ECS task memory is above 80% in ${var.environment}

    Service: {{ecs_service_name.name}}
    Task: {{ecs_task_family.name}}

    @slack-datadog-alerts
  EOT

  query = "avg(last_5m):avg:ecs.fargate.mem.usage{env:${var.environment}} by {ecs_service_name,ecs_task_family} > 80"

  monitor_thresholds {
    critical = 80
    warning  = 70
  }

  notify_no_data = false

  tags = [
    "env:${var.environment}",
    "service:ecs",
    "team:platform"
  ]
}

resource "datadog_monitor" "ecs_task_failed" {
  count = var.enable_ecs_monitoring ? 1 : 0

  name    = "[${var.environment}] ECS Tasks Failing"
  type    = "metric alert"
  message = <<-EOT
    ECS tasks are failing in ${var.environment}

    Service: {{ecs_service_name.name}}

    Check ECS console for task errors

    @slack-datadog-alerts
    @pagerduty-critical
  EOT

  query = "sum(last_5m):diff(sum:aws.ecs.service.running{env:${var.environment}} by {ecs_service_name}) < -1"

  monitor_thresholds {
    critical = -1
  }

  notify_no_data = false

  tags = [
    "env:${var.environment}",
    "service:ecs",
    "team:platform"
  ]
}

# RDS Monitors
resource "datadog_monitor" "rds_cpu_high" {
  count = var.enable_rds_monitoring ? 1 : 0

  name    = "[${var.environment}] RDS CPU High"
  type    = "metric alert"
  message = <<-EOT
    RDS CPU is above 80% in ${var.environment}

    Database: {{dbinstanceidentifier.name}}

    Consider scaling up the instance or optimizing queries

    @slack-datadog-alerts
  EOT

  query = "avg(last_10m):avg:aws.rds.cpuutilization{env:${var.environment}} by {dbinstanceidentifier} > 80"

  monitor_thresholds {
    critical = 80
    warning  = 70
  }

  notify_no_data = false

  tags = [
    "env:${var.environment}",
    "service:rds",
    "team:platform"
  ]
}

resource "datadog_monitor" "rds_connections_high" {
  count = var.enable_rds_monitoring ? 1 : 0

  name    = "[${var.environment}] RDS High Connection Count"
  type    = "metric alert"
  message = <<-EOT
    RDS connection count is high in ${var.environment}

    Database: {{dbinstanceidentifier.name}}
    Current: {{value}} connections

    May need to increase max_connections or investigate connection leaks

    @slack-datadog-alerts
  EOT

  query = "avg(last_5m):avg:aws.rds.database_connections{env:${var.environment}} by {dbinstanceidentifier} > 80"

  monitor_thresholds {
    critical = 80
    warning  = 60
  }

  notify_no_data = false

  tags = [
    "env:${var.environment}",
    "service:rds",
    "team:platform"
  ]
}

resource "datadog_monitor" "rds_storage_low" {
  count = var.enable_rds_monitoring ? 1 : 0

  name    = "[${var.environment}] RDS Low Free Storage"
  type    = "metric alert"
  message = <<-EOT
    RDS free storage is below 20% in ${var.environment}

    Database: {{dbinstanceidentifier.name}}
    Free space: {{value}} bytes

    Consider increasing allocated storage

    @slack-datadog-alerts
    @pagerduty-infrastructure
  EOT

  query = "avg(last_15m):avg:aws.rds.free_storage_space{env:${var.environment}} by {dbinstanceidentifier} < 2000000000"

  monitor_thresholds {
    critical = 2000000000  # 2GB
    warning  = 5000000000  # 5GB
  }

  notify_no_data = false

  tags = [
    "env:${var.environment}",
    "service:rds",
    "team:platform"
  ]
}

resource "datadog_monitor" "rds_replica_lag" {
  count = var.enable_rds_monitoring ? 1 : 0

  name    = "[${var.environment}] RDS Replica Lag High"
  type    = "metric alert"
  message = <<-EOT
    RDS read replica lag is high in ${var.environment}

    Database: {{dbinstanceidentifier.name}}
    Lag: {{value}} seconds

    Check replica health and network connectivity

    @slack-datadog-alerts
  EOT

  query = "avg(last_5m):avg:aws.rds.replica_lag{env:${var.environment}} by {dbinstanceidentifier} > 30"

  monitor_thresholds {
    critical = 30  # 30 seconds
    warning  = 10  # 10 seconds
  }

  notify_no_data = false

  tags = [
    "env:${var.environment}",
    "service:rds",
    "team:platform"
  ]
}
