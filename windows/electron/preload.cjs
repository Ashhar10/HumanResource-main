// Preload script for Elipse HR Portal Electron Desktop App
const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  platform: process.platform,
  isDesktop: true
});
