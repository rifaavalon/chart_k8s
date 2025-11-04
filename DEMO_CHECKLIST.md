# Demo Presentation Checklist

## 📅 One Week Before

- [ ] Test complete demo flow start to finish
- [ ] Verify AWS account has sufficient credits/limits
- [ ] Confirm Datadog trial account is active
- [ ] Review presentation script thoroughly
- [ ] Practice timing each section
- [ ] Prepare backup slides for deep-dive questions
- [ ] Test screen sharing setup
- [ ] Verify all tools are latest versions

## 📅 One Day Before

- [ ] Run through demo one final time
- [ ] Deploy backup environment and leave running
- [ ] Clear browser cache and cookies
- [ ] Organize terminal windows
- [ ] Test microphone and camera
- [ ] Print presentation script as reference
- [ ] Charge laptop fully
- [ ] Prepare backup laptop (if available)

## 📅 2 Hours Before

- [ ] Close all unnecessary applications
- [ ] Disable notifications (Slack, email, etc.)
- [ ] Set phone to Do Not Disturb
- [ ] Open all necessary browser tabs
- [ ] Arrange terminal windows
- [ ] Test internet connection
- [ ] Verify Datadog login works
- [ ] Verify AWS CLI access works

## 📅 30 Minutes Before

### Environment Setup

```bash
# Set environment variables
export DD_API_KEY="your-api-key"
export DD_SITE="datadoghq.com"
export AWS_REGION="us-east-1"

# Navigate to project
cd ~/datadog_pres

# Verify tools
terraform version
ansible --version
aws sts get-caller-identity
```

### Terminal Windows

**Terminal 1: Terraform**
```bash
cd ~/datadog_pres/terraform
clear
```

**Terminal 2: Ansible**
```bash
cd ~/datadog_pres/ansible
clear
```

**Terminal 3: Monitoring**
```bash
cd ~/datadog_pres
clear
```

**Terminal 4: Spare**
```bash
cd ~/datadog_pres
clear
```

### Browser Tabs (in order)

1. **Datadog - Infrastructure List**
   - URL: https://app.datadoghq.com/infrastructure
   - Filter: `env:dev`

2. **Datadog - Host Map**
   - URL: https://app.datadoghq.com/infrastructure/map

3. **Datadog - Metrics Explorer**
   - URL: https://app.datadoghq.com/metric/explorer
   - Query: `system.cpu.user`

4. **Datadog - Dashboards**
   - URL: https://app.datadoghq.com/dashboard/lists

5. **GitHub Repository** (if needed)
   - Your repo URL

6. **Architecture Diagrams** (local)
   - File: `file:///Users/chrishickey/datadog_pres/diagrams/architecture.md`

7. **Project Plan** (local)
   - File: `file:///Users/chrishickey/datadog_pres/docs/project-plan.md`

### Application Setup

- [ ] Text editor ready (VS Code, Vim, etc.)
- [ ] Terminal font size increased (for visibility)
- [ ] Screen resolution optimized for sharing
- [ ] Dark mode enabled (easier on eyes)
- [ ] Presentation script open in separate window

## 📅 5 Minutes Before

- [ ] Join meeting
- [ ] Test screen sharing
- [ ] Test audio
- [ ] Mute notifications one final time
- [ ] Take a deep breath
- [ ] Have water nearby
- [ ] Pull up first slide/terminal

## ✅ During Presentation

### Keep Nearby

- [ ] Presentation script (docs/presentation-script.md)
- [ ] Quick reference card (docs/quick-reference.md)
- [ ] Water
- [ ] Pen and paper for notes
- [ ] Timer/clock visible

### Remember To

- [ ] Speak clearly and at steady pace
- [ ] Explain what you're doing as you type
- [ ] Pause for questions
- [ ] Stay calm if something goes wrong
- [ ] Use the backup environment if needed
- [ ] Watch the time
- [ ] Engage the audience

### If Something Goes Wrong

**Option 1: Retry**
- Explain what happened
- Show the troubleshooting process
- This demonstrates real-world skills

**Option 2: Use Backup**
- Switch to pre-deployed backup environment
- "Let me show you the result from our backup environment"

**Option 3: Pivot**
- Move to next section
- "While that's processing, let me show you..."
- Come back to it later if time permits

## 📋 Content Checklist

### Introduction (5 min)
- [ ] Introduced yourself
- [ ] Explained customer scenario
- [ ] Outlined agenda
- [ ] Set expectations

### Architecture (10 min)
- [ ] Showed architecture diagram
- [ ] Explained each component
- [ ] Highlighted scalability
- [ ] Discussed tech stack support

### POC Demo (25 min)
- [ ] Showed Terraform code
- [ ] Ran terraform plan
- [ ] Applied infrastructure
- [ ] Showed Ansible role structure
- [ ] Deployed Datadog agents
- [ ] Validated in Datadog UI
- [ ] Demonstrated scalability

### Deployment Strategy (15 min)
- [ ] Explained POC phase
- [ ] Walked through Dev approach
- [ ] Described Test validation
- [ ] Detailed Production rollout
- [ ] Showed CI/CD pipelines
- [ ] Discussed teams involved
- [ ] Covered risk management
- [ ] Presented timeline

### Q&A (10 min)
- [ ] Invited questions
- [ ] Answered thoroughly
- [ ] Provided additional context
- [ ] Offered to follow up

### Closing
- [ ] Summarized key points
- [ ] Thanked audience
- [ ] Expressed enthusiasm

## 🎯 Key Metrics to Mention

- [ ] Deployment time: < 15 minutes
- [ ] Success rate: > 99%
- [ ] Scalability: 3 to 300+ instances
- [ ] Automation: 100% coverage
- [ ] Time to value: 5 minutes
- [ ] Team efficiency: 80% improvement
- [ ] Project duration: 9-10 weeks
- [ ] Zero downtime deployments

## 📊 Backup Materials

### If Time Runs Over
**Skip/Shorten**:
- Detailed code walkthrough
- Some diagram explanations
- Extended Q&A

**Must Include**:
- Live demo (even abbreviated)
- Project management approach
- Timeline and milestones

### If Time Permits
**Bonus Topics**:
- Multi-cloud support
- Container integration
- Advanced Datadog features
- Cost optimization
- Security best practices

## 🔄 Post-Presentation

- [ ] Save all terminal outputs
- [ ] Export any Datadog screenshots
- [ ] Cleanup demo environment (or save for questions)
- [ ] Note any questions you couldn't answer
- [ ] Follow up on action items
- [ ] Request feedback
- [ ] Self-assessment of what went well/improve

## 📝 Notes Section

**Unexpected Questions Asked**:
_Take notes during presentation_

---

**Issues Encountered**:
_Document any problems_

---

**Timing Actual**:
- Introduction: ___ min
- Architecture: ___ min
- POC Demo: ___ min
- Deployment Strategy: ___ min
- Q&A: ___ min
- Total: ___ min

---

**Things to Improve Next Time**:
_Post-presentation reflection_

---

## ⭐ Final Reminders

**You Are Demonstrating**:
- Technical expertise ✅
- Project management skills ✅
- Customer-facing abilities ✅
- Problem-solving approach ✅
- Leadership and communication ✅

**Keys to Success**:
- **Confidence**: You know this material
- **Clarity**: Speak clearly, explain as you go
- **Calm**: Stay composed if issues arise
- **Connection**: Engage with your audience
- **Competence**: Show your expertise

---

**Good luck! You've prepared well, and you're ready for this! 🚀**
