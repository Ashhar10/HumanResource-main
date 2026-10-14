const { app, BrowserWindow, shell, Menu } = require('electron');
const path = require('path');
const { fork } = require('child_process');
const fs = require('fs');
const http = require('http');

let mainWindow = null;
let zkAgentProcess = null;
let localServer = null;

// -----------------------------------------------------------------------------
// 1. Embedded Local Loopback Web Server (Guarantees all /icons/ paths load)
// -----------------------------------------------------------------------------
function startLocalFileServer(distDir) {
  const mimeTypes = {
    '.html': 'text/html; charset=utf-8',
    '.js': 'application/javascript; charset=utf-8',
    '.mjs': 'application/javascript; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
    '.webp': 'image/webp',
    '.woff': 'font/woff',
    '.woff2': 'font/woff2',
    '.ttf': 'font/ttf'
  };

  return new Promise((resolve, reject) => {
    const server = http.createServer((req, res) => {
      let rawUrl = decodeURI(req.url.split('?')[0]);
      if (rawUrl === '/' || rawUrl === '') rawUrl = '/index.html';

      // Remove leading slashes for path.join
      let safePath = path.normalize(path.join(distDir, rawUrl));

      // Security check: ensure path is within distDir
      if (!safePath.startsWith(path.normalize(distDir))) {
        res.writeHead(403);
        res.end('Forbidden');
        return;
      }

      // Fallback to index.html for client-side routing if file doesn't exist and not an icon/asset
      if (!fs.existsSync(safePath) || fs.statSync(safePath).isDirectory()) {
        safePath = path.join(distDir, 'index.html');
      }

      const ext = path.extname(safePath).toLowerCase();
      const contentType = mimeTypes[ext] || 'application/octet-stream';

      fs.readFile(safePath, (err, data) => {
        if (err) {
          res.writeHead(404, { 'Content-Type': 'text/plain' });
          res.end('File not found');
        } else {
          res.writeHead(200, {
            'Content-Type': contentType,
            'Cache-Control': 'no-cache',
            'Access-Control-Allow-Origin': '*'
          });
          res.end(data);
        }
      });
    });

    server.on('error', (err) => reject(err));

    // Bind strictly to 127.0.0.1 on an automatic free ephemeral port (port 0)
    server.listen(0, '127.0.0.1', () => {
      const port = server.address().port;
      localServer = server;
      console.log(`[Desktop App] Internal asset server listening on http://127.0.0.1:${port}`);
      resolve(`http://127.0.0.1:${port}`);
    });
  });
}

function startBackgroundSyncAgent() {
  const candidatePaths = [
    path.resolve(__dirname, '../../windows/zk-sync-agent/index.js'),
    path.resolve(__dirname, '../../zk-sync-agent/index.js'),
    path.resolve(__dirname, '../../source-code/zk-sync-agent/index.js'),
    path.resolve(__dirname, '../zk-sync-agent/index.js'),
    path.resolve(process.cwd(), 'zk-sync-agent/index.js'),
    path.resolve(process.cwd(), 'windows/zk-sync-agent/index.js')
  ];
  const agentPath = candidatePaths.find(p => fs.existsSync(p));
  if (agentPath) {
    try {
      console.log(`[Desktop App] Starting ZKTeco background sync agent from ${agentPath}...`);
      zkAgentProcess = fork(agentPath, [], {
        cwd: path.dirname(agentPath),
        env: { ...process.env, NODE_ENV: 'production' },
        silent: true
      });

      zkAgentProcess.stdout?.on('data', (data) => {
        const msg = data.toString().trim();
        if (msg) console.log(`[ZK Agent] ${msg}`);
      });

      zkAgentProcess.stderr?.on('data', (data) => {
        const msg = data.toString().trim();
        if (msg) console.error(`[ZK Agent Error] ${msg}`);
      });

      zkAgentProcess.on('exit', (code) => {
        console.log(`[Desktop App] ZK Agent exited with code ${code}`);
        zkAgentProcess = null;
      });
    } catch (err) {
      console.warn('[Desktop App] Could not start ZK Agent child process:', err.message);
    }
  }
}

function stopBackgroundSyncAgent() {
  if (zkAgentProcess) {
    try {
      console.log('[Desktop App] Terminating ZKTeco background sync agent...');
      zkAgentProcess.kill();
    } catch (e) {}
    zkAgentProcess = null;
  }
  if (localServer) {
    try {
      localServer.close();
    } catch (e) {}
    localServer = null;
  }
}

// -----------------------------------------------------------------------------
// 3. Create Native Desktop Application Window
// -----------------------------------------------------------------------------
async function createWindow() {
  // Resolve high-resolution Windows icon (.ico preferred for taskbar and title bar)
  let iconPath = path.join(__dirname, '../build/icon.ico');
  if (!fs.existsSync(iconPath)) {
    iconPath = path.join(__dirname, '../public/icon.ico');
  }
  if (!fs.existsSync(iconPath)) {
    iconPath = path.join(__dirname, '../public/icons/logo.png');
  }

  mainWindow = new BrowserWindow({
    width: 1440,
    height: 900,
    minWidth: 1024,
    minHeight: 700,
    title: 'Elipse HR Portal',
    icon: fs.existsSync(iconPath) ? iconPath : undefined,
    backgroundColor: '#000000',
    autoHideMenuBar: true,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.cjs'),
      webSecurity: true,
      allowRunningInsecureContent: false
    }
  });

  Menu.setApplicationMenu(null);

  const distDir = path.join(__dirname, '../dist');
  if (fs.existsSync(distDir)) {
    try {
      const serverUrl = await startLocalFileServer(distDir);
      mainWindow.loadURL(serverUrl);
    } catch (e) {
      console.error('[Desktop App] Failed to start local server, fallback to loadFile:', e);
      mainWindow.loadFile(path.join(distDir, 'index.html'));
    }
  } else {
    mainWindow.loadURL('http://localhost:5173');
  }

  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      shell.openExternal(url);
      return { action: 'deny' };
    }
    return { action: 'allow' };
  });

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

// -----------------------------------------------------------------------------
// 4. Single Instance Lock & App Lifecycle
// -----------------------------------------------------------------------------
const gotTheLock = app.requestSingleInstanceLock();

if (!gotTheLock) {
  app.quit();
} else {
  app.on('second-instance', () => {
    if (mainWindow) {
      if (mainWindow.isMinimized()) mainWindow.restore();
      mainWindow.focus();
    }
  });

  app.whenReady().then(() => {
    createWindow();
    startBackgroundSyncAgent();

    app.on('activate', () => {
      if (BrowserWindow.getAllWindows().length === 0) createWindow();
    });
  });

  app.on('window-all-closed', () => {
    stopBackgroundSyncAgent();
    if (process.platform !== 'darwin') {
      app.quit();
    }
  });

  app.on('before-quit', () => {
    stopBackgroundSyncAgent();
  });
}
