# MCP Diagram Tools Setup Guide

## 🎨 Installed MCP Servers

I've installed two powerful diagram MCP servers for Claude Code:

### 1. **Excalidraw MCP Server** ⭐
- **Package:** `mcp-excalidraw-server`
- **Purpose:** Create beautiful hand-drawn style diagrams
- **Features:**
  - Real-time diagram creation
  - WebSocket synchronization
  - Multiple shape types (rectangles, arrows, text, etc.)
  - Optional live canvas at http://localhost:3000

### 2. **Draw.io MCP Server** ⭐
- **Package:** `drawio-mcp-server`
- **Purpose:** Professional enterprise diagrams
- **Features:**
  - Full draw.io functionality
  - Shape library access
  - Programmatic diagram control
  - **Requires:** Browser extension

---

## 📦 Installation Status

```bash
✅ mcp-excalidraw-server installed
✅ drawio-mcp-server installed
✅ Located in: node_modules/
```

---

## 🔧 Configuration for Claude Desktop

### Option 1: Using Local Node Modules (Recommended)

Add this to your Claude Desktop config file:

**Location:**
- **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`
- **Linux:** `~/.config/Claude/claude_desktop_config.json`

**Configuration:**
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
    },
    "drawio": {
      "command": "node",
      "args": [
        "/home/ubuntu/federated-imputation-central/node_modules/drawio-mcp-server/build/index.js"
      ]
    }
  }
}
```

### Option 2: Using npx (Alternative)

```json
{
  "mcpServers": {
    "excalidraw": {
      "command": "npx",
      "args": ["-y", "mcp-excalidraw-server"],
      "env": {
        "ENABLE_CANVAS_SYNC": "false"
      }
    },
    "drawio": {
      "command": "npx",
      "args": ["-y", "drawio-mcp-server"]
    }
  }
}
```

---

## 🚀 Quick Start

### Using Excalidraw MCP

Once configured, you can ask Claude Code to create diagrams:

```
"Create a system architecture diagram showing:
- Azure cloud with DNAstack
- Mali on-prem with DRS/WesKIT
- ILIFU on-prem
- Central UI connecting them all"
```

**Available Tools:**
- `create_element` - Create shapes (rectangle, ellipse, arrow, text, etc.)
- `batch_create_elements` - Create complex diagrams
- `update_element` - Modify existing elements
- `delete_element` - Remove elements
- `align_elements` - Align multiple elements
- `group_elements` - Group elements together

### Using Draw.io MCP

**⚠️ Important:** Requires browser extension first!

1. **Install Extension:**
   - Chrome: https://chrome.google.com/webstore/detail/okdbbjbbccdhhfaefmcmekalmmdjjide
   - Firefox: https://addons.mozilla.org/firefox/addon/drawio-mcp-extension/

2. **Open Draw.io:**
   - Go to https://app.diagrams.net/
   - Ensure extension shows green icon (connected)

3. **Use in Claude:**
   ```
   "Create a flowchart in draw.io showing the job submission process"
   ```

**Available Tools:**
- `add-rectangle` - Add rectangle shapes
- `add-edge` - Connect shapes with arrows
- `add-cell-of-shape` - Add from shape library
- `get-selected-cell` - Inspect selected elements
- `delete-cell-by-id` - Remove elements
- `list-paged-model` - View diagram structure

---

## 🎯 Which Tool to Use?

### Use **Excalidraw** When:
- ✅ Quick sketches and brainstorming
- ✅ Hand-drawn aesthetic needed
- ✅ Whiteboard-style diagrams
- ✅ No browser extension desired
- ✅ Working offline

### Use **Draw.io** When:
- ✅ Professional enterprise diagrams
- ✅ Need specific shapes (AWS, Azure, GCP icons)
- ✅ Complex flowcharts
- ✅ Formal documentation
- ✅ Fine-grained control over styling

---

## 📊 Example Usage

### Example 1: Create Architecture Diagram (Excalidraw)

**Prompt:**
```
Using Excalidraw, create a simple federated architecture diagram with:
1. A central box labeled "Central UI"
2. Three boxes around it: "Azure", "Mali", "ILIFU"
3. Arrows connecting each to the central UI
4. Use different colors for cloud vs on-prem
```

### Example 2: Create Flowchart (Draw.io)

**Prompt:**
```
Using draw.io, create a flowchart for job submission:
1. Start node: "User uploads file"
2. Decision: "Has credentials?"
3. If yes: "Submit job" → "Queue processing" → "Complete"
4. If no: "Show error"
5. Connect with arrows
```

---

## 🔄 Optional: Enable Live Canvas (Excalidraw)

If you want to see diagrams in real-time on a web canvas:

### 1. Install Frontend Dependencies

```bash
cd /home/ubuntu/federated-imputation-central
npm install express ws @excalidraw/excalidraw react react-dom
```

### 2. Enable Canvas Sync

Update your Claude config to set `ENABLE_CANVAS_SYNC=true`:

```json
{
  "mcpServers": {
    "excalidraw": {
      "command": "node",
      "args": [
        "/home/ubuntu/federated-imputation-central/node_modules/mcp-excalidraw-server/src/index.js"
      ],
      "env": {
        "ENABLE_CANVAS_SYNC": "true",
        "EXPRESS_SERVER_URL": "http://localhost:3000"
      }
    }
  }
}
```

### 3. Start Canvas Server

```bash
# In the Excalidraw package directory
cd node_modules/mcp-excalidraw-server/frontend
npm install
npm run build
npm start
```

### 4. View Live Diagrams

Open http://localhost:3000 in your browser to see diagrams created in real-time!

---

## 🛠️ Troubleshooting

### Issue: MCP Tools Not Showing in Claude

**Solution:**
1. Ensure Claude Desktop is restarted after config changes
2. Check that paths in config are absolute (not relative)
3. Verify Node.js is installed: `node --version`
4. Check Claude logs for errors

### Issue: Draw.io Extension Not Connecting

**Solution:**
1. Ensure you're on https://app.diagrams.net/
2. Check extension is installed and enabled
3. Look for green icon in extension toolbar
4. Refresh the page
5. Check browser console for errors

### Issue: Excalidraw Canvas Not Loading

**Solution:**
1. Set `ENABLE_CANVAS_SYNC=false` if you don't need live canvas
2. Or ensure frontend is built: `npm run build` in frontend folder
3. Check port 3000 is not in use: `lsof -i :3000`

### Issue: Permission Denied Errors

**Solution:**
```bash
# Fix node_modules permissions
chmod +x node_modules/mcp-excalidraw-server/src/index.js
chmod +x node_modules/drawio-mcp-server/build/index.js
```

---

## 📚 Additional Resources

### Excalidraw MCP
- **GitHub:** https://github.com/yctimlin/mcp_excalidraw
- **Demo Video:** https://youtu.be/RRN7AF7QIew
- **Documentation:** See `node_modules/mcp-excalidraw-server/README.md`

### Draw.io MCP
- **GitHub:** https://github.com/lgazo/drawio-mcp-server
- **Extension (Chrome):** https://chrome.google.com/webstore/detail/okdbbjbbccdhhfaefmcmekalmmdjjide
- **Extension (Firefox):** https://addons.mozilla.org/firefox/addon/drawio-mcp-extension/
- **Documentation:** See `node_modules/drawio-mcp-server/README.md`

### General MCP
- **MCP Specification:** https://modelcontextprotocol.io
- **MCP Inspector:** https://modelcontextprotocol.io/docs/tools/inspector
- **Claude Desktop Docs:** https://claude.ai/desktop

---

## ✅ Next Steps

1. **Configure Claude Desktop:**
   - Add MCP servers to config file
   - Restart Claude Desktop

2. **Install Draw.io Extension** (if using draw.io):
   - Install from Chrome/Firefox store
   - Open https://app.diagrams.net/
   - Verify connection (green icon)

3. **Test Integration:**
   - Ask Claude Code to create a simple diagram
   - Verify tools are available
   - Create your architecture diagram!

4. **Save Diagrams:**
   ```bash
   # Create diagrams folder if not exists
   mkdir -p /home/ubuntu/federated-imputation-central/docs/diagrams

   # Save exported diagrams here
   ```

---

## 🎨 Example Prompts to Try

Once configured, try these prompts in Claude Code:

**Simple Architecture:**
```
Using Excalidraw, create a simple diagram showing our microservices:
- API Gateway at the top
- 6 microservices below it
- PostgreSQL database at the bottom
- Use arrows to show connections
```

**Detailed Flowchart:**
```
Using draw.io, create a sequence diagram for job submission showing:
- User uploads file
- Frontend validates
- API Gateway authenticates
- Job Processor checks credentials
- Celery Worker processes job
- Notification sent
Use different colors for each component
```

**Network Topology:**
```
Create a diagram showing:
- Central UI (gold box)
- Azure cloud (blue) with DNAstack
- Mali on-prem (green) with DRS/WesKIT
- ILIFU on-prem (green) with attestation
Connect all to Central UI with labeled arrows
```

Happy diagramming! 🎉
