# 🚀 Quick Start Guide
## Xtreme XA-vI ® Cyber KI Elektronikx-Center-Matte®

Get up and running in 5 minutes!

---

## 📱 Step 1: Install Termux

1. **Download Termux** from F-Droid (recommended):
   - Visit: https://f-droid.org/en/packages/com.termux/
   - Or use Google Play Store (older version)

2. **Open Termux** and wait for initial setup

---

## ⚡ Step 2: One-Command Installation

Copy and paste this into Termux:

```bash
curl -fsSL https://raw.githubusercontent.com/xxxyalaxx90xxx/Alex-/main/install.sh | bash
```

**OR** manual installation:

```bash
pkg update && pkg upgrade -y
pkg install git -y
git clone https://github.com/xxxyalaxx90xxx/Alex-.git
cd Alex-
chmod +x *.sh
./install.sh
```

---

## ⏱️ Step 3: Wait for Installation

The installation will:
- ✅ Update system packages (2-5 min)
- ✅ Install development tools (3-10 min)
- ✅ Setup GitHub CLI
- ✅ Configure stylish theme
- ✅ Create utility scripts

**Total time**: ~15-20 minutes depending on internet speed

---

## 🎨 Step 4: Restart Termux

After installation:

```bash
exit
```

Then reopen Termux app. You should see:

```
╔═══════════════════════════════════════════════╗
║  Xtreme XA-vI ® Development Environment       ║
║  Realme c63 (RMX3939) - Optimiert             ║
╚═══════════════════════════════════════════════╝
```

---

## 🔐 Step 5: Setup GitHub Authentication

```bash
gh auth login
```

Follow the prompts:
1. Select "GitHub.com"
2. Select "HTTPS"
3. Authenticate via browser
4. Done!

---

## 🎯 Step 6: Test Your Setup

### Check System Info
```bash
system-info.sh
```

### Test Performance
```bash
./Alex-/performance-optimizer.sh test
```

### Search GitHub
```bash
gh-search.sh "machine learning"
```

### Clone a Repository
```bash
./Alex-/auto-clone.sh facebook/react
```

---

## ⚡ Quick Commands Reference

After setup, use these commands:

| Command | What it does |
|---------|--------------|
| `update-system.sh` | Update all packages |
| `system-info.sh` | Show device info |
| `turbo` | Boost performance |
| `gst` | Git status |
| `gpl` | Git pull |
| `gps` | Git push |
| `cleanup` | Clean cache |

---

## 🎨 Customize Your Terminal

### Change Colors

Edit `~/.termux/colors.properties`:
```bash
nano ~/.termux/colors.properties
```

### Change Prompt

Edit `~/.bashrc`:
```bash
nano ~/.bashrc
```

Apply changes:
```bash
source ~/.bashrc
```

---

## 🔧 Advanced Setup

### Performance Tuning

```bash
cd ~/Alex-
./performance-optimizer.sh turbo
```

### API Management

```bash
cd ~/Alex-
./api-manager.sh setup
```

### SSH Keys

```bash
# Generate key
ssh-keygen -t ed25519

# View public key
cat ~/.ssh/id_ed25519.pub

# Add to GitHub: Settings → SSH Keys
```

---

## 🆘 Troubleshooting

### Problem: Installation fails

```bash
# Change repository mirror
termux-change-repo

# Try again
./install.sh
```

### Problem: Permission denied

```bash
# Allow storage access
termux-setup-storage

# Make scripts executable
chmod +x ~/Alex-/*.sh
```

### Problem: Slow internet

```bash
# Optimize DNS
echo "nameserver 1.1.1.1" > $PREFIX/etc/resolv.conf
```

---

## 📚 Next Steps

1. **Read Full Documentation**: `cat ~/Alex-/TERMUX_SETUP.md`
2. **Setup Your Projects**: `mkdir ~/projects && cd ~/projects`
3. **Install More Tools**: Check TERMUX_SETUP.md for options
4. **Join Community**: Check GitHub issues and discussions

---

## 🌟 Pro Tips

### Tip 1: Use Aliases
```bash
alias projects='cd ~/projects'
alias dev='cd ~/projects && code-server'
```

### Tip 2: Background Processes
```bash
# Run server in background
npm run dev &

# View running jobs
jobs

# Bring to foreground
fg
```

### Tip 3: Split Screen
```bash
# Install tmux (already installed)
tmux

# Split vertical: Ctrl+B then %
# Split horizontal: Ctrl+B then "
# Switch panes: Ctrl+B then arrow keys
```

### Tip 4: Exclude from Battery Optimization

Settings → Apps → Termux → Battery → Unrestricted

This prevents Android from killing Termux processes.

---

## 📊 Benchmarks

On Realme c63 (RMX3939):

| Task | Time | Notes |
|------|------|-------|
| Full Installation | ~15-20 min | First time |
| System Update | ~2-3 min | Regular |
| Clone React.js | ~1-2 min | With dependencies |
| Build Node.js App | ~30-60 sec | Small project |
| Python Script | <1 sec | Simple scripts |

---

## 🎯 Common Workflows

### Web Development
```bash
# Setup Node.js project
cd ~/projects
npm init -y
npm install express
code-server .  # VS Code in browser
```

### Python Development
```bash
# Create virtual environment
cd ~/projects
python -m venv myenv
source myenv/bin/activate
pip install requests flask
```

### Git Workflow
```bash
# Clone, edit, commit, push
gh-search.sh "your-topic"
./auto-clone.sh username/repo
cd ~/projects/repo
# Make changes...
gst               # git status
ga .              # git add .
gc -m "message"   # git commit
gps               # git push
```

---

## ✅ Checklist: You're Ready When...

- [ ] Termux opens with Cyber-Style theme
- [ ] `system-info.sh` shows device info
- [ ] `gh auth status` shows "Logged in"
- [ ] `node --version` shows Node.js version
- [ ] `python --version` shows Python version
- [ ] Can clone GitHub repos
- [ ] Can run performance tests

---

## 🎊 Congratulations!

You now have a complete development environment on your Android device!

**What's Next?**
- Build your first app
- Contribute to open source
- Learn new technologies
- Create amazing projects

---

**Happy Coding! 💻✨**

---

**Support**: https://github.com/xxxyalaxx90xxx/Alex-/issues  
**Documentation**: https://github.com/xxxyalaxx90xxx/Alex-/blob/main/TERMUX_SETUP.md  
**Version**: 1.0.0
