# Demo Setup Instructions

## What's Been Added

I've added a complete ECS + RDS stack with Datadog monitoring (currently commented out). This gives you a production-ready demo showing:

### Infrastructure Components (Ready to Enable)
1. **ECS Fargate Service** - Running Nginx with Datadog agent sidecar
2. **RDS PostgreSQL Database** - db.t3.micro with enhanced monitoring
3. **10 New Datadog Monitors** - ECS and RDS specific alerts
4. **All integrated with your existing** - VPC, ALB, EC2 instances

### Datadog Monitors Added
**ECS Monitors:**
- ECS Task CPU High (>80%)
- ECS Task Memory High (>80%)
- ECS Tasks Failing

**RDS Monitors:**
- RDS CPU High (>80%)
- RDS High Connection Count (>80 connections)
- RDS Low Free Storage (<2GB)
- RDS Replica Lag High (>30 seconds)

## Tonight: Test Your Current Setup

**You can push and test tonight** - the ECS/RDS modules are commented out, so only your existing infrastructure will deploy:

```bash
git add .
git commit -m "Prepare demo infrastructure with ECS and RDS ready"
git push origin main
```

This will deploy:
- ✅ VPC, EC2 instances, ALB (existing)
- ✅ Datadog monitors for EC2 (existing)
- ❌ ECS and RDS (commented out - ready for tomorrow)

### Required Secret for Tonight

**DD_APP_KEY** - Add this tonight for Datadog monitors to work:
1. Go to: https://us5.datadoghq.com/organization-settings/application-keys
2. Click "New Key" → Name: "Terraform - GitHub Actions"
3. Copy the key value
4. Add to GitHub: Settings → Secrets → Actions → New secret
   - Name: `DD_APP_KEY`
   - Value: [paste the application key]

## Tomorrow Morning: Enable ECS + RDS Demo

**Step 1: Add DB_PASSWORD Secret** (1 minute)
- Go to GitHub: Settings → Secrets → Actions → New secret
  - Name: `DB_PASSWORD`
  - Value: Choose a secure password (e.g., `MySecureP@ssw0rd123!`)

**Step 2: Uncomment the Code** (2 minutes)

Edit `terraform/main.tf` around line 78:
```hcl
# Change this:
# # ECS Service with Datadog sidecar
# module "ecs" {

# To this (remove the leading #):
# ECS Service with Datadog sidecar
module "ecs" {
```

Do the same for:
- `module "rds"` block (remove all `#` symbols)
- Change `enable_ecs_monitoring = false` to `true`
- Change `enable_rds_monitoring = false` to `true`

Edit `terraform/outputs.tf` around line 59:
- Uncomment all ECS and RDS outputs (remove `#` symbols)

Edit `.github/workflows/deploy-dev.yml` lines 63 and 75:
```yaml
# Change this:
# UNCOMMENT FOR DEMO: -var="db_password=${{ secrets.DB_PASSWORD }}" \

# To this:
-var="db_password=${{ secrets.DB_PASSWORD }}" \
```

**Step 3: Deploy** (15 minutes)
```bash
git add .
git commit -m "Enable ECS and RDS for demo"
git push origin main
```

This will deploy in ~15 minutes:
- 2 ECS tasks running Nginx with Datadog agent sidecars
- PostgreSQL RDS instance (db.t3.micro)
- 10 new Datadog monitors

### 2. What You'll See in Datadog

**ECS Metrics (visible in ~2 minutes):**
- `ecs.fargate.cpu.percent` - Task CPU usage
- `ecs.fargate.mem.usage` - Task memory usage
- `aws.ecs.service.running` - Number of running tasks

**RDS Metrics (visible in ~5 minutes):**
- `aws.rds.cpuutilization` - Database CPU
- `aws.rds.database_connections` - Active connections
- `aws.rds.free_storage_space` - Available storage

**Infrastructure View:**
- Filter by `env:dev` to see all resources
- Your existing EC2 instances + new ECS tasks

### 3. Demo Script

**Opening:**
"Let me show you how our GitOps workflow automatically deploys and monitors infrastructure."

**Step 1: Show the Code**
```bash
# Show the Terraform modules
ls -la terraform/modules/
# ecs/  rds/  datadog/  vpc/  compute/  alb/

# Show the Datadog monitors
cat terraform/modules/datadog/main.tf | grep "resource \"datadog_monitor\""
```

**Step 2: Show GitHub Actions**
- Navigate to: https://github.com/[your-repo]/actions
- Click on the latest "Deploy to Development" run
- Show the Terraform apply step
- Point out ECS and RDS resources being created

**Step 3: Show Datadog Dashboard**
- Go to: https://us5.datadoghq.com/dashboard/lists
- Open the "[dev] Infrastructure Overview" dashboard
- Show real-time metrics from EC2, ECS, and RDS

**Step 4: Show Monitors**
- Go to: https://us5.datadoghq.com/monitors/manage
- Filter by `env:dev`
- Show the new monitors (should see ~15 total)
- Click into the "ECS Task CPU High" monitor
- Explain the alert thresholds and notification channels

**Step 5: Trigger an Alert (Optional)**
```bash
# SSH into an EC2 instance and spike CPU
yes > /dev/null &
yes > /dev/null &
yes > /dev/null &

# Wait 2-3 minutes, then show the alert in Datadog
# Kill the processes
killall yes
```

**Step 6: Show the Value**
"With this setup, when we push code:
- Infrastructure is automatically deployed
- Monitoring is automatically configured
- Alerts are automatically created
- Everything is tracked in git"

### 4. Terraform Outputs After Deploy

After deployment completes, you can show:
```bash
cd terraform

# Show ECS cluster
terraform output ecs_cluster_name
# Output: dev-datadog-demo-cluster

# Show RDS endpoint
terraform output rds_endpoint
# Output: dev-demo-db.xxxxx.us-east-1.rds.amazonaws.com:5432

# Show Datadog dashboard URL
terraform output datadog_dashboard_url
# Direct link to your dashboard
```

## Cost Estimate

**New Resources:**
- ECS Fargate (2 tasks): ~$15/month
- RDS db.t3.micro: ~$15/month
- **Total Additional: ~$30/month**

**To Clean Up After Demo:**
```bash
cd terraform
terraform destroy \
  -var-file=environments/dev/terraform.tfvars \
  -var="datadog_api_key=$DD_API_KEY" \
  -var="datadog_app_key=$DD_APP_KEY" \
  -var="db_password=$DB_PASSWORD"
```

## Troubleshooting

### 401 Unauthorized Error
- **Cause:** DD_APP_KEY secret is missing or invalid
- **Fix:** Create new Application Key and add to GitHub Secrets

### RDS Takes Forever
- **Expected:** RDS takes 5-10 minutes to create
- **Normal:** This is AWS's typical RDS creation time

### ECS Tasks Not Starting
- **Check:** ECS console for task failures
- **Common Cause:** Datadog API key invalid
- **Fix:** Verify DD_API_KEY in GitHub Secrets

### Monitors Not Showing Data
- **Wait Time:** Metrics may take 2-5 minutes to appear
- **Check:** Datadog Metrics Explorer for `ecs.fargate.*` and `aws.rds.*`

## Quick Reference

**Datadog Links:**
- API Keys: https://us5.datadoghq.com/organization-settings/api-keys
- App Keys: https://us5.datadoghq.com/organization-settings/application-keys
- Monitors: https://us5.datadoghq.com/monitors/manage
- Dashboards: https://us5.datadoghq.com/dashboard/lists
- Infrastructure: https://us5.datadoghq.com/infrastructure/map?fillby=avg%3Acpuutilization&filter=env%3Adev

**AWS Console:**
- ECS: https://console.aws.amazon.com/ecs/
- RDS: https://console.aws.amazon.com/rds/

**Key Filters:**
- Datadog: `env:dev`
- GitHub Actions: Repository → Actions → "Deploy to Development"
