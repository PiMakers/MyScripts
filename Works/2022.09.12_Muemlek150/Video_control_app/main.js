const { app, BrowserWindow } = require('electron')
const path = require('path')

const createWindow = () => {
  const mainWindow = new BrowserWindow({
    show: false,
    fullscreen: true,
    alwaysOnTop: true,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: true,
      contextIsolation: false,
      nativeWindowOpen: true
    }
  }
)

mainWindow.once('ready-to-show', () => {
    mainWindow.show()
})

mainWindow.fullScreenable = false;
mainWindow.menuBarVisible = false;

mainWindow.loadFile('index.html')
// mainWindow.webContents.openDevTools()
}

app.whenReady().then(() => {

  createWindow()

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow()
  })
})



app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})
