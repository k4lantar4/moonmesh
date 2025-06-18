# 🌐 EasyTier & MoonMesh - Unified Manager

**One-script solution for EasyTier mesh network installation and management**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/shell-bash-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-linux-blue.svg)](https://www.linux.org/)

## 🚀 Quick Start

### One-Command Install & Run
```bash
curl -fsSL https://raw.githubusercontent.com/k4lantar4/moonmesh/main/moonmesh.sh | sudo bash -s -- --install
```

### Auto Install (No Prompts)
```bash
curl -fsSL https://raw.githubusercontent.com/k4lantar4/moonmesh/main/moonmesh.sh | sudo bash -s -- --auto
```

### Run Without Installing
```bash
curl -fsSL https://raw.githubusercontent.com/k4lantar4/moonmesh/main/moonmesh.sh | sudo bash
```

### After Installation
```bash
sudo moonmesh
```

## 📋 Usage Options

| Command | Description |
|---------|-------------|
| `moonmesh.sh --install` | Install EasyTier & MoonMesh |
| `moonmesh.sh --auto` | Auto install without prompts |
| `moonmesh.sh --help` | Show help message |
| `moonmesh.sh` | Show selection menu |
| `moonmesh` | Run manager (after install) |

## ✨ Features

- **🎯 One-Script Solution** - Install and manage from single script
- **⚡ Quick Setup** - Ready in 30 seconds
- **🖥️ Simple Menu** - 11 practical options
- **📊 Live Monitoring** - Real-time peers and routes
- **🐕 Smart Watchdog** - Ping-based stability monitoring
- **⚖️ Load Balancer** - HAProxy integration
- **🔧 Network Optimization** - Ubuntu-specific tuning
- **🌐 Multi-Protocol** - UDP/TCP/WebSocket support

## 🎮 Main Menu

```
╔════════════════════════════════════════╗
║            EasyTier Manager            ║
║       Simple Mesh Network Solution    ║
╠════════════════════════════════════════╣
║  Version: 3.0 (K4lantar4)             ║
║  GitHub: k4lantar4/moonmesh            ║
╠════════════════════════════════════════╣
║        EasyTier Core Installed        ║
╚════════════════════════════════════════╝

[1]  Quick Connect to Network
[2]  Live Peers Monitor
[3]  Display Routes
[4]  Peer-Center
[5]  Display Secret Key
[6]  View Service Status
[7]  Watchdog & Stability
[8]  HAProxy Load Balancer
[9]  Restart Service
[10] Remove Service
[11] Network Optimization
[0]  Exit
```

## 🔗 Quick Connect Example

```bash
# Server 1 (Central)
🌐 Peer Addresses: [ENTER for reverse mode]
🏠 Local IP [10.10.10.1]: 
🏷️  Hostname [server1-1234]: 
🔌 Port [1377]: 
🔐 Network Secret [auto-generated]: mynetwork123

# Server 2 (Connect to Server 1)
🌐 Peer Addresses: 1.2.3.4
🏠 Local IP [10.10.10.2]: 
🔐 Network Secret: mynetwork123
```

## 🐕 Watchdog Features

- **🏓 Ping-based Monitoring** - Monitor tunnel connectivity
- **📊 Health Checks** - Service status and performance
- **🔄 Auto-restart** - Configurable intervals (30min to weekly)
- **🧹 Log Management** - Automatic cleanup
- **⚡ Performance Tuning** - Network optimization

## 🛠️ Advanced Usage

### Installation Methods
```bash
# Method 1: Direct install
curl -fsSL https://raw.githubusercontent.com/k4lantar4/moonmesh/main/moonmesh.sh | sudo bash -s -- --install

# Method 2: Auto install
curl -fsSL https://raw.githubusercontent.com/k4lantar4/moonmesh/main/moonmesh.sh | sudo bash -s -- --auto

# Method 3: Download & install
wget https://raw.githubusercontent.com/k4lantar4/moonmesh/main/moonmesh.sh
sudo bash moonmesh.sh --install
```

### Management Commands
```bash
# Run manager
sudo moonmesh

# Quick connect (option 1)
sudo moonmesh

# Monitor peers (option 2)  
sudo moonmesh

# Setup watchdog (option 7)
sudo moonmesh

# Network optimization (option 11)
sudo moonmesh
```

## 🔧 Troubleshooting

### Common Issues

**Connection Problems:**
```bash
# Check firewall
sudo ufw allow 1377/udp
sudo ufw allow 1377/tcp

# Check service status
sudo systemctl status easytier
```

**Service Won't Start:**
```bash
# View logs
sudo journalctl -u easytier.service -f

# Restart service
sudo moonmesh  # Option 9
```

**Performance Issues:**
```bash
# Apply network optimization
sudo moonmesh  # Option 11

# Setup ping watchdog
sudo moonmesh  # Option 7 → Option 1
```

## 📊 Default Configuration

- **Local IP:** `10.10.10.1`
- **Port:** `1377`
- **Protocol:** `UDP` (recommended)
- **Multi-thread:** Enabled
- **IPv6:** Disabled
- **Encryption:** Enabled
- **Auto-restart:** Enabled

## 🤝 Contributing

Inspired by [K4lantar4/MoonMesh](https://github.com/K4lantar4/MoonMesh) and powered by [EasyTier](https://github.com/EasyTier/EasyTier).

## 📞 Support

- 🐛 [Report Issues](https://github.com/k4lantar4/moonmesh/issues)
- 💬 [Discussions](https://github.com/k4lantar4/moonmesh/discussions)
- 📖 [Documentation](https://github.com/k4lantar4/moonmesh)

---

**Made with ❤️ by K4lantar4**
