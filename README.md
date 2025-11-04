# Datadog Agent Deployment - Technical Presentation

## Overview

This repository contains a complete demonstration of deploying the Datadog monitoring agent across multiple environments using Infrastructure as Code (IaC) and configuration management tools. The solution showcases deployment automation, project management, and scalable architecture design.

**Presentation Duration**: 60 minutes
**Target Audience**: Implementation Services Team
**Scenario**: Customer-facing deployment from POC to Production

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Demo Walkthrough](#demo-walkthrough)
- [Project Management](#project-management)
- [Deployment Strategy](#deployment-strategy)
- [Scaling](#scaling)
- [Troubleshooting](#troubleshooting)
- [Additional Resources](#additional-resources)

## 🚀 Quick Start

### 1. Setup Your Environment

```bash
# Clone or navigate to this repository
cd datadog_pres

# Run the setup script
./scripts/setup-demo.sh
```

This will:
- Check prerequisites (Terraform, Ansible, AWS CLI)
- Validate AWS credentials
- Configure Datadog API key
- Create SSH keys
- Initialize Terraform
- Set up demo aliases

### 2. Deploy to Development

```bash
# Deploy infrastructure and Datadog agents to Dev
./scripts/deploy-environment.sh dev
```

### 3. View Results

```bash
# Check agent status
cd ansible
ansible all -i inventory/dev.ini -m shell -a "datadog-agent status" --become

# View in Datadog UI
# Navigate to: https://app.datadoghq.com/infrastructure
```

### 4. Cleanup

```bash
# Destroy all resources
./scripts/cleanup.sh dev
```

## ✅ GitHub Actions - Fully Functional!

The GitHub Actions workflows are **ready to use**! They include:

- ✅ Automated dev deployments on push to main
- ✅ Approval-gated test deployments
- ✅ Batched production deployments (30% / 40% / 30%)
- ✅ Dynamic inventory generation
- ✅ Full CI/CD automation

**Quick Setup (5 minutes):**
```bash
./scripts/setup-github-actions.sh
```

**Then configure GitHub Secrets and Environments.** See [docs/GITHUB_ACTIONS_SETUP.md](docs/GITHUB_ACTIONS_SETUP.md) for complete instructions.

**For demo presentations:** You can still run locally using `./scripts/deploy-environment.sh` for better visibility.

## 🏗️ Architecture

### High-Level Design

```
┌─────────────────┐
│  GitHub Repo    │
│  (Source Code)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ GitHub Actions  │
│   (CI/CD)       │
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌─────────┐ ┌─────────┐
│Terraform│ │ Ansible │
│  (IaC)  │ │ (Config)│
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────────────────────┐
│   AWS Infrastructure    │
│  ┌─────────────────┐    │
│  │ Dev (3 inst)    │    │
│  │ Test (5 inst)   │    │
│  │ Prod (10 inst)  │    │
│  └─────────────────┘    │
└───────────┬─────────────┘
            │
            ▼
     ┌──────────────┐
     │   Datadog    │
     │   Platform   │
     └──────────────┘
```

### Key Components

| Component | Purpose | Technology |
|-----------|---------|------------|
| **Infrastructure** | Provision cloud resources | Terraform |
| **Configuration** | Deploy and configure agents | Ansible |
| **CI/CD** | Automate deployments | GitHub Actions |
| **Monitoring** | Collect metrics, logs, traces | Datadog |

For detailed architecture diagrams, see [diagrams/architecture.md](diagrams/architecture.md)

## 📁 Project Structure

```
datadog_pres/
├── README.md                          # This file
├── .github/
│   └── workflows/                     # CI/CD pipelines
│       ├── deploy-dev.yml            # Auto-deploy to dev
│       ├── deploy-test.yml           # Approval-gated test deploy
│       └── deploy-prod.yml           # Production deployment
├── terraform/                         # Infrastructure as Code
│   ├── main.tf                       # Root module
│   ├── variables.tf                  # Variable definitions
│   ├── outputs.tf                    # Output values
│   ├── modules/                      # Reusable modules
│   │   ├── vpc/                      # VPC networking
│   │   ├── compute/                  # EC2 instances
│   │   └── alb/                      # Load balancer
│   └── environments/                 # Environment configs
│       ├── dev/terraform.tfvars      # Dev variables
│       ├── test/terraform.tfvars     # Test variables
│       └── prod/terraform.tfvars     # Prod variables
├── ansible/                          # Configuration Management
│   ├── ansible.cfg                   # Ansible configuration
│   ├── inventory/                    # Target hosts
│   │   ├── dev.ini
│   │   ├── test.ini
│   │   └── prod.ini
│   ├── playbooks/                    # Orchestration playbooks
│   │   └── deploy-datadog.yml
│   └── roles/                        # Reusable roles
│       └── datadog-agent/
│           ├── tasks/                # Installation tasks
│           ├── templates/            # Config templates
│           ├── defaults/             # Default variables
│           └── handlers/             # Service handlers
├── scripts/                          # Helper scripts
│   ├── setup-demo.sh                # Environment setup
│   ├── deploy-environment.sh        # Deploy automation
│   └── cleanup.sh                   # Teardown script
├── docs/                             # Documentation
│   ├── project-plan.md              # Full project plan
│   └── presentation-script.md       # Presentation guide
└── diagrams/                         # Architecture diagrams
    └── architecture.md              # Mermaid diagrams
```

## ✅ Prerequisites

### Required Software

| Tool | Version | Purpose | Installation |
|------|---------|---------|--------------|
| **Terraform** | >= 1.0 | Infrastructure provisioning | [terraform.io](https://www.terraform.io/downloads) |
| **Ansible** | >= 2.10 | Configuration management | `pip install ansible` |
| **AWS CLI** | >= 2.0 | AWS interaction | [aws.amazon.com/cli](https://aws.amazon.com/cli/) |
| **Python** | >= 3.8 | Ansible runtime | [python.org](https://www.python.org/downloads/) |
| **Git** | >= 2.0 | Version control | [git-scm.com](https://git-scm.com/) |

### Required Accounts

1. **AWS Account** with permissions to create:
   - VPC, Subnets, Route Tables
   - EC2 instances
   - Security Groups
   - Load Balancers
   - IAM roles

2. **Datadog Account** with:
   - API key
   - Application key (for advanced features)
   - Trial account works: [datadoghq.com/free-trial](https://www.datadoghq.com/free-trial/)

### Environment Variables

```bash
export DD_API_KEY="your-datadog-api-key"
export DD_SITE="datadoghq.com"  # or datadoghq.eu, etc.
export AWS_REGION="us-east-1"
export AWS_ACCESS_KEY_ID="your-aws-key"
export AWS_SECRET_ACCESS_KEY="your-aws-secret"
```

## 🎬 Demo Walkthrough

### Phase 1: POC (Proof of Concept)

**Objective**: Validate deployment on a single instance

```bash
# 1. Navigate to terraform directory
cd terraform

# 2. Review configuration
cat main.tf
cat environments/dev/terraform.tfvars

# 3. Initialize Terraform
terraform init

# 4. Plan deployment
terraform plan -var-file=environments/dev/terraform.tfvars

# 5. Apply (creates infrastructure)
terraform apply -var-file=environments/dev/terraform.tfvars
```

### Phase 2: Deploy Datadog Agent

```bash
# 1. Navigate to ansible directory
cd ../ansible

# 2. Review playbook
cat playbooks/deploy-datadog.yml

# 3. Review role structure
tree roles/datadog-agent/

# 4. Deploy agents
ansible-playbook -i inventory/dev.ini playbooks/deploy-datadog.yml

# 5. Verify deployment
ansible all -i inventory/dev.ini -m shell -a "datadog-agent status" --become
```

### Phase 3: Validate in Datadog UI

1. Navigate to: https://app.datadoghq.com/infrastructure
2. Look for hosts tagged with `env:dev`
3. Verify metrics are flowing
4. Check integration dashboards

### Phase 4: Demonstrate Scalability

```bash
# 1. Edit instance count
vim terraform/environments/dev/terraform.tfvars
# Change: instance_count = 3 → instance_count = 6

# 2. Plan changes
terraform plan -var-file=environments/dev/terraform.tfvars

# 3. Apply changes
terraform apply -var-file=environments/dev/terraform.tfvars

# 4. Deploy to new instances
ansible-playbook -i inventory/dev.ini playbooks/deploy-datadog.yml
```

## 📊 Project Management

### Timeline

| Phase | Duration | Activities |
|-------|----------|------------|
| **POC** | 2 weeks | Manual deployment, validation, stakeholder demo |
| **Dev** | 2 weeks | Automation development, IaC, CI/CD pipeline |
| **Test** | 2 weeks | QA testing, performance validation |
| **Prod** | 3 weeks | Change approval, phased rollout, validation |
| **Total** | **9-10 weeks** | POC to production |

### Key Milestones

- ✅ Week 2: POC validated
- ✅ Week 4: Automation complete
- ⏳ Week 6: Test environment deployed
- ⏳ Week 9: Production deployed
- ⏳ Week 10: Project closure

### Team Structure

| Role | Responsibility | Time |
|------|----------------|------|
| Project Manager | Timeline, stakeholders | 50% |
| Solutions Architect | Design, decisions | 30% |
| DevOps Engineer | Terraform, CI/CD | 100% |
| Automation Engineer | Ansible, scripts | 100% |
| Implementation Engineer | Deployment, support | 100% |
| QA Engineer | Testing, validation | 75% |

For complete project plan, see [docs/project-plan.md](docs/project-plan.md)

## 🚀 Deployment Strategy

### Environment Progression

```
POC → Dev → Test → Production
```

### Approval Gates

| Environment | Approval Required | Approver |
|-------------|-------------------|----------|
| POC | None | - |
| Dev | Automatic | - |
| Test | Team Lead | Engineering Manager |
| Production | Change Board | CAB + Stakeholders |

### Deployment Approaches

**Development**:
- Automatic on code push
- Fast iteration
- No approval required

**Test**:
- Manual trigger
- Approval gate
- Full QA validation

**Production**:
- Rolling deployment (batches)
- 24-hour soak between batches
- Immediate rollback capability

### Production Rollout Strategy

```
Batch 1: 3 instances  → Monitor 24h → ✓
Batch 2: 4 instances  → Monitor 24h → ✓
Batch 3: Remaining    → Final validation
```

## 📈 Scaling

### Horizontal Scaling

**Add more instances**:
```bash
# Edit terraform variables
vim terraform/environments/prod/terraform.tfvars
# Change: instance_count = 10 → instance_count = 20

# Apply changes
terraform apply -var-file=environments/prod/terraform.tfvars

# Deploy agents
ansible-playbook -i inventory/prod.ini playbooks/deploy-datadog.yml
```

### Multi-Environment Scaling

**Deploy to new environment**:
```bash
# 1. Create new environment config
cp terraform/environments/dev/terraform.tfvars terraform/environments/staging/terraform.tfvars

# 2. Customize values
vim terraform/environments/staging/terraform.tfvars

# 3. Deploy
./scripts/deploy-environment.sh staging
```

### Multi-Cloud Support

The Ansible playbooks are cloud-agnostic and work on:
- AWS EC2
- Azure VMs
- GCP Compute Engine
- On-premises servers

Simply adjust the Terraform provider and the same Ansible code works.

### Container Support

For containerized environments:

**Docker**:
```yaml
- name: Deploy Datadog container agent
  docker_container:
    name: datadog-agent
    image: datadog/agent:latest
    env:
      DD_API_KEY: "{{ datadog_api_key }}"
      DD_SITE: "{{ datadog_site }}"
```

**Kubernetes**:
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: datadog-agent
spec:
  template:
    spec:
      containers:
      - name: datadog-agent
        image: datadog/agent:latest
        env:
        - name: DD_API_KEY
          valueFrom:
            secretKeyRef:
              name: datadog-secret
              key: api-key
```

## 🔧 Troubleshooting

### Common Issues

#### Issue: Terraform state lock

**Symptom**: `Error: Error locking state`

**Solution**:
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

#### Issue: Ansible connection timeout

**Symptom**: `Failed to connect to the host via ssh`

**Solution**:
```bash
# 1. Verify SSH key
ls -l ~/.ssh/datadog-demo-key.pem

# 2. Test SSH manually
ssh -i ~/.ssh/datadog-demo-key.pem ec2-user@<instance-ip>

# 3. Check security groups allow SSH from your IP
```

#### Issue: Datadog agent not reporting

**Symptom**: No data in Datadog UI

**Solution**:
```bash
# 1. Check agent status
ansible all -i inventory/dev.ini -m shell -a "datadog-agent status" --become

# 2. Check logs
ansible all -i inventory/dev.ini -m shell -a "tail -n 50 /var/log/datadog/agent.log" --become

# 3. Verify API key
ansible all -i inventory/dev.ini -m shell -a "grep api_key /etc/datadog-agent/datadog.yaml" --become
```

#### Issue: AWS credentials not found

**Symptom**: `Unable to locate credentials`

**Solution**:
```bash
# Configure AWS CLI
aws configure

# Or export credentials
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_REGION="us-east-1"
```

### Debug Mode

**Terraform**:
```bash
export TF_LOG=DEBUG
terraform plan
```

**Ansible**:
```bash
ansible-playbook playbooks/deploy-datadog.yml -vvv
```

### Validation Commands

```bash
# Check Terraform state
terraform show

# List Terraform outputs
terraform output

# Test Ansible connectivity
ansible all -i inventory/dev.ini -m ping

# Get Datadog agent version
ansible all -i inventory/dev.ini -m shell -a "datadog-agent version" --become
```

## 📚 Additional Resources

### Documentation

- [Presentation Script](docs/presentation-script.md) - Complete presentation guide
- [Project Plan](docs/project-plan.md) - Detailed project timeline and management
- [Architecture Diagrams](diagrams/architecture.md) - Visual architecture references

### External Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [Datadog Agent Documentation](https://docs.datadoghq.com/agent/)
- [Datadog API Reference](https://docs.datadoghq.com/api/)

### Demo Tips

1. **Practice First**: Run through the entire demo at least twice
2. **Pre-Create Backup**: Have a pre-deployed environment as backup
3. **Terminal Setup**: Use multiple terminal windows for parallel viewing
4. **Browser Tabs**: Pre-open Datadog UI tabs
5. **Timing**: Use a timer to track presentation sections
6. **Questions**: Prepare for common questions (see presentation script)

## 🎯 Success Criteria

### Deployment Metrics
- ✅ Deployment time: < 15 minutes per environment
- ✅ Success rate: > 99%
- ✅ Automation coverage: 100%
- ✅ Rollback time: < 5 minutes

### Operational Metrics
- ✅ Agent uptime: > 99.9%
- ✅ Data completeness: > 99%
- ✅ Alert response: < 5 minutes

### Business Metrics
- ✅ Time to value: 5 minutes (metrics visible)
- ✅ Scalability: 10x growth without rework
- ✅ Team efficiency: 80% reduction in manual work

## 🤝 Contributing

This is a demonstration project. For improvements:

1. Fork the repository
2. Create a feature branch
3. Test thoroughly
4. Submit a pull request

## 📝 License

This project is for demonstration purposes.

## 🙋 Support

For questions about this demo:
- Review the [Troubleshooting](#troubleshooting) section
- Check the [Presentation Script](docs/presentation-script.md)
- Refer to the [Project Plan](docs/project-plan.md)

---

**Good luck with your presentation! 🚀**

Remember:
- Stay calm and confident
- Focus on the value delivered
- Demonstrate thought leadership
- Be prepared for questions
- Show your project management skills

You've got this! 💪
