# Quick Start: Creating Architecture Diagrams

## ✅ What's Been Set Up

```
✓ MCP Excalidraw Server installed
✓ MCP Draw.io Server installed
✓ Mermaid diagram templates created
✓ Diagram folder structure ready
✓ Color standards documented
✓ Tool guides written
```

## 🚀 3-Minute Quick Start

### Option A: Use Mermaid (Fastest, No Installation)

**Step 1:** Open this file
```bash
docs/SIMPLE_ARCHITECTURE.md
```

**Step 2:** Copy the mermaid code block (lines 5-59)

**Step 3:** Go to https://mermaid.live and paste

**Step 4:** Export PNG
- Click "Actions" → "Export as PNG"
- Save to `docs/diagrams/architecture.png`

**Done!** ✅ You now have a professional architecture diagram

### Option B: Use Excalidraw (Hand-Drawn Style)

**Step 1:** Go to https://excalidraw.com

**Step 2:** Draw your diagram
- Click Rectangle tool (or press `R`)
- Draw boxes for: Azure, Mali, ILIFU, Central UI
- Click Arrow tool (or press `A`)
- Connect boxes
- Click Text tool (or press `T`)
- Add labels

**Step 3:** Export
- Menu → Export → PNG
- Check "Background"
- Download

**Done!** ✅ Beautiful whiteboard-style diagram

### Option C: Use MCP with Claude Code (AI-Assisted)

**Step 1:** Configure Claude Desktop

Edit config file:
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

Add this:
```json
{
  "mcpServers": {
    "excalidraw": {
      "command": "node",
      "args": [
        "/home/ubuntu/federated-imputation-central/node_modules/mcp-excalidraw-server/src/index.js"
      ],
      "env": {
        "ENABLE_CANVAS_SYNC": "false"
      }
    }
  }
}
```

**Step 2:** Restart Claude Desktop

**Step 3:** Ask Claude to create a diagram
```
Using Excalidraw MCP, create a federated architecture diagram with:
- Central UI (gold box) in the center
- Azure (blue) on the left
- Mali (green) on the right
- ILIFU (green) on the bottom
- Arrows connecting all to Central UI
```

**Done!** ✅ Claude creates the diagram for you

---

## 📚 Available Resources

### Documentation Files
| File | Purpose |
|------|---------|
| [SIMPLE_ARCHITECTURE.md](SIMPLE_ARCHITECTURE.md) | Simplified diagram matching your whiteboard |
| [ARCHITECTURE_DIAGRAM.md](ARCHITECTURE_DIAGRAM.md) | Complete technical diagrams (4 types) |
| [DIAGRAM_TOOLS_GUIDE.md](DIAGRAM_TOOLS_GUIDE.md) | Comprehensive tool comparison |
| [MCP_DIAGRAM_SETUP.md](MCP_DIAGRAM_SETUP.md) | AI-assisted diagram setup |
| [diagrams/README.md](diagrams/README.md) | Diagram standards and conventions |

### Diagram Templates
| Template | Location | Export To |
|----------|----------|-----------|
| High-Level Architecture | SIMPLE_ARCHITECTURE.md | https://mermaid.live |
| Microservices Detail | ARCHITECTURE_DIAGRAM.md | https://mermaid.live |
| Job Flow Sequence | ARCHITECTURE_DIAGRAM.md | https://mermaid.live |
| Service Discovery | ARCHITECTURE_DIAGRAM.md | https://mermaid.live |
| Database Schema (ER) | ARCHITECTURE_DIAGRAM.md | https://mermaid.live |

### Tools Installed
| Tool | Status | Use Case |
|------|--------|----------|
| **mcp-excalidraw-server** | ✅ Installed | Hand-drawn diagrams |
| **drawio-mcp-server** | ✅ Installed | Professional diagrams |

---

## 🎯 Recommended Workflow

### For Your Project

**1. Quick Sketches** → Use Excalidraw
- Go to https://excalidraw.com
- Draw in 5 minutes
- Export PNG

**2. Documentation** → Use Mermaid
- Edit `.md` files
- Push to GitHub
- Auto-renders everywhere

**3. Presentations** → Use draw.io
- Go to https://app.diagrams.net
- Use templates
- Export high-res PNG

**4. AI-Assisted** → Use MCP Servers
- Configure Claude Desktop
- Describe diagram in plain English
- Claude creates it

---

## 💡 Common Tasks

### Task: Export Current Architecture

```bash
# 1. Open in browser
open docs/SIMPLE_ARCHITECTURE.md

# 2. Copy mermaid code

# 3. Go to mermaid.live and paste

# 4. Export
# Actions → Export as PNG → Save to docs/diagrams/
```

### Task: Create New Diagram

```bash
# 1. Choose tool
# Mermaid: For version-controlled diagrams
# Excalidraw: For quick sketches
# draw.io: For professional diagrams

# 2. Create diagram

# 3. Save
mkdir -p docs/diagrams
# Save as: architecture-[description].png
```

### Task: Update Existing Diagram

```bash
# 1. Edit source
code docs/ARCHITECTURE_DIAGRAM.md

# 2. Re-export
# Visit mermaid.live → paste → export

# 3. Replace file
mv ~/Downloads/diagram.png docs/diagrams/architecture.png

# 4. Commit
git add docs/
git commit -m "docs: Update architecture diagram"
```

---

## 🎨 Quick Reference: Color Codes

Copy these hex codes for consistent styling:

```
Azure/Cloud:     #1E90FF (Dodger Blue)
On-Premise:      #32CD32 (Lime Green)
Central System:  #FFD700 (Gold)
External APIs:   #FF6347 (Tomato Red)
Databases:       #9370DB (Medium Purple)
Frontend:        #61dafb (React Blue)
Gateway:         #ff6b6b (Light Red)
Microservices:   #4dabf7 (Light Blue)
Workers:         #ffd43b (Yellow)
```

---

## 🔗 Quick Links

| Resource | URL |
|----------|-----|
| **Mermaid Live** | https://mermaid.live |
| **Excalidraw** | https://excalidraw.com |
| **draw.io** | https://app.diagrams.net |
| **D2 Playground** | https://play.d2lang.com |
| **PlantUML** | https://plantuml.com |

---

## ❓ Troubleshooting

### Can't see Mermaid diagrams in GitHub?
→ Push to GitHub, they auto-render

### Need higher resolution?
→ In Mermaid Live: Actions → Export → Choose 2x or 3x scale

### Want hand-drawn style?
→ Use Excalidraw: https://excalidraw.com

### MCP tools not working?
→ Check [MCP_DIAGRAM_SETUP.md](MCP_DIAGRAM_SETUP.md) for configuration

### Need help choosing a tool?
→ See [DIAGRAM_TOOLS_GUIDE.md](DIAGRAM_TOOLS_GUIDE.md)

---

## 🎓 Next Steps

1. **Create Your First Diagram**
   - Try the 3-minute Mermaid option above
   - Export to `docs/diagrams/`

2. **Configure MCP (Optional)**
   - Follow [MCP_DIAGRAM_SETUP.md](MCP_DIAGRAM_SETUP.md)
   - Let Claude create diagrams for you

3. **Establish Standards**
   - Use color codes consistently
   - Follow naming conventions
   - Document new diagrams

4. **Share with Team**
   - Push diagrams to GitHub
   - Link in documentation
   - Update as architecture evolves

---

**✨ You're all set! Start creating beautiful architecture diagrams.**
