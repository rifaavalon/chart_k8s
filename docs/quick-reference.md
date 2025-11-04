# Quick Reference Card

## Essential Commands

### Terraform

```bash
# Initialize
terraform init

# Plan (Dev)
terraform plan -var-file=environments/dev/terraform.tfvars

# Apply (Dev)
terraform apply -var-file=environments/dev/terraform.tfvars

# Destroy (Dev)
terraform destroy -var-file=environments/dev/terraform.tfvars

# Show outputs
terraform output

# Show state
terraform show
```

### Ansible

```bash
# Deploy agents
ansible-playbook -i inventory/dev.ini playbooks/deploy-datadog.yml

# Check connectivity
ansible all -i inventory/dev.ini -m ping

# Check agent status
ansible all -i inventory/dev.ini -m shell -a "datadog-agent status" --become

# Run ad-hoc command
ansible all -i inventory/dev.ini -m shell -a "uptime" --become
```

### Demo Scripts

```bash
# Setup environment
./scripts/setup-demo.sh

# Deploy to environment
./scripts/deploy-environment.sh dev
./scripts/deploy-environment.sh test
./scripts/deploy-environment.sh prod

# Cleanup
./scripts/cleanup.sh dev
```

### Environment Variables

```bash
# Datadog
export DD_API_KEY="your-api-key"
export DD_SITE="datadoghq.com"

# AWS
export AWS_REGION="us-east-1"
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
```

## Presentation Flow

### Section 1: Introduction (5 min)
- Introduce the scenario
- Show the customer's needs
- Preview the agenda

### Section 2: Architecture (10 min)
- Display architecture diagram
- Explain components
- Highlight scalability

### Section 3: POC Demo (25 min)

**Part 1: Infrastructure (7 min)**
```bash
cd terraform
cat main.tf
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
```

**Part 2: Ansible Deployment (10 min)**
```bash
cd ../ansible
tree roles/datadog-agent/
ansible-playbook -i inventory/dev.ini playbooks/deploy-datadog.yml
```

**Part 3: Validation (5 min)**
- Show Datadog UI
- Infrastructure list
- Metrics explorer
- Dashboards

**Part 4: Scalability (3 min)**
- Edit instance_count
- Run terraform plan
- Explain scaling

### Section 4: Deployment Strategy (15 min)
- POC phase
- Dev environment
- Test environment
- Production rollout
- Teams involved
- Risk management

### Section 5: Q&A (10 min)
- Be ready for questions
- Refer to presentation script

## Key Talking Points

### Scalability
- "Change one variable to scale from 3 to 300 instances"
- "Same code across all environments"
- "Supports multiple tech stacks automatically"

### Automation
- "Fully automated - zero manual steps"
- "Deployment completes in under 15 minutes"
- "Idempotent - safe to run multiple times"

### Reliability
- "Rolling deployments minimize risk"
- "Immediate rollback capability"
- "Comprehensive testing at each stage"

### Project Management
- "Clear timeline from POC to production"
- "Risk mitigation strategies for each phase"
- "Cross-functional team coordination"

## Demo Checklist

**Before Presentation**:
- [ ] AWS credentials configured
- [ ] Datadog API key set
- [ ] SSH key created
- [ ] Terraform initialized
- [ ] Ansible installed
- [ ] Browser tabs prepared
- [ ] Terminal windows arranged
- [ ] Backup environment ready

**Terminal Windows**:
1. Terraform directory
2. Ansible directory
3. Monitoring/logs
4. Spare

**Browser Tabs**:
1. Datadog Infrastructure
2. Datadog Metrics
3. GitHub repo
4. Architecture diagrams
5. Project plan

## Troubleshooting Quick Fixes

**Terraform lock**:
```bash
terraform force-unlock <LOCK_ID>
```

**Ansible timeout**:
```bash
# Increase timeout
export ANSIBLE_TIMEOUT=60
```

**Agent not reporting**:
```bash
ansible all -i inventory/dev.ini -m shell -a "systemctl restart datadog-agent" --become
```

**Check logs**:
```bash
ansible all -i inventory/dev.ini -m shell -a "tail -50 /var/log/datadog/agent.log" --become
```

## Success Metrics to Highlight

- **Deployment time**: < 15 minutes
- **Success rate**: 99%+
- **Scalability**: 10x growth supported
- **Automation**: 100% coverage
- **Time to value**: 5 minutes
- **Team efficiency**: 80% improvement

## URLs

- Datadog UI: https://app.datadoghq.com
- Datadog Docs: https://docs.datadoghq.com
- Terraform Docs: https://www.terraform.io/docs
- Ansible Docs: https://docs.ansible.com
