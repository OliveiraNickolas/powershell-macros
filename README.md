# MacroExecutor

A powerful PowerShell-based macro recorder and executor with a modern GUI for automating mouse and keyboard tasks on Windows.

---

## 🚀 Features

### Core Functionality
- **🎬 Record Macros** - Capture mouse clicks, movements, and keystrokes in real-time
- **▶️ Playback** - Execute macros with precise timing
- **🔄 Loop & Repeat** - Run macros indefinitely or a specific number of times
- **⏸️ Pause/Resume** - Control execution on the fly

### Advanced Recording
- **Smart Delay Detection** - Automatically captures timing between actions
- **Modifier Key Support** - Records Ctrl, Alt, Shift, and Windows key combinations
- **Text Input Capture** - Records typed text as single actions
- **Coordinate Tracking** - Real-time mouse position display

### Visual Editor
- **Full Macro Editing** - Insert, delete, move, and modify actions after recording
- **Context Menu** - Right-click for quick actions (insert delay, message, text)
- **Zoom Support** - Ctrl + Mouse Wheel to adjust grid font size
- **Cell Editing** - Triple-click to edit any cell value

### Interface
- **Modern Dark Theme** - Clean cyan/purple color scheme
- **Borderless Windows** - Draggable title bars with custom minimize/close buttons
- **Real-time Logging** - See macro execution progress

---

## 📥 Installation

### Requirements
- Windows 10/11
- PowerShell 5.1+ or PowerShell 7+
- .NET Framework 4.5+

### Quick Start

```powershell
# Clone or download this repository
cd macros

# Run the macro executor
powershell -ExecutionPolicy Bypass -File macros.ps1
```

---

## 🎮 Usage

### Recording a Macro

1. Click **GRAVAR** (or press **F9**) to start recording
2. Perform your mouse clicks and keyboard actions
3. Press **F9** again or click **PARAR** to stop
4. Enter a name for your macro
5. Click **GUARDAR** to save

### Editing a Recorded Macro

1. Click **GRAVAR** to open the recorder
2. Click **EDITAR** to modify an existing macro
3. Use the grid to:
   - **Triple-click** a cell to edit its value
   - **Right-click** a row to insert/delete/move actions
   - Click **X** button to delete a row
   - Use **↑/↓** arrows to reorder actions

### Playing a Macro

1. Select a macro from the dropdown
2. Configure options:
   - **Loop** - Repeat indefinitely
   - **Repetir** - Run N times
3. Click **PLAY** to start
4. Use **PAUSA** to pause/resume
5. Use **STOP** to cancel

---

## ⌨️ Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `F9` | Start/Stop recording |
| `Ctrl + Scroll` | Zoom editor grid |
| `Ctrl + +` | Zoom in |
| `Ctrl + -` | Zoom out |

---

## 📁 File Structure

```
macros/
├── macros.ps1          # Main application (this file)
├── recorder.ps1        # Legacy recorder module
├── mouseposition.ps1   # Legacy mouse tracking module
├── macros/             # Stored macro files (JSON)
│   ├── 010_example.json
│   └── ...
└── README.md           # This file
```

---

## 🔧 Technical Details

### Supported Actions

| Type | Description | Parameters |
|------|-------------|------------|
| `Click` | Left mouse click | X, Y coordinates |
| `RightClick` | Right mouse click | X, Y coordinates |
| `MoveMouse` | Move cursor | X, Y coordinates |
| `Delay` | Wait | Milliseconds, optional message |
| `TypeText` | Type text | Text string |
| `Message` | Display message | Text string |
| `Keyboard` | Key press | Any key or combination |

### Keyboard Support

- **All letters** (A-Z)
- **Numbers** (0-9, both row and numpad)
- **Function keys** (F1-F12)
- **Navigation** (Arrow keys, Home, End, Page Up/Down)
- **Special keys** (Enter, Escape, Tab, Space, Backspace, Delete, Insert)
- **Modifier combinations** (Ctrl, Alt, Shift, Win + any key)

### Storage Format

Macros are saved as JSON files in the `./macros/` folder:

```json
{
  "name": "Example Macro",
  "order": 10,
  "actions": [
    {"Type": "Click", "X": 100, "Y": 200},
    {"Type": "Delay", "Milliseconds": 500, "Message": "", "Load": 0},
    {"Type": "TypeText", "Text": "Hello World"},
    {"Type": "Enter"}
  ]
}
```

---

## 🛠️ Advanced Usage

### Running from VS Code

The script auto-detects VS Code and launches in a separate PowerShell window:

```powershell
powershell -ExecutionPolicy Bypass -File macros.ps1
```

### Custom Execution Policy

If you encounter execution policy errors:

```powershell
# Run once for current session
powershell -ExecutionPolicy Bypass -File macros.ps1

# Or set permanently (requires Admin)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 📝 Tips

- **Minimum Delay**: Adjust the "Delay min" setting to filter out very short delays during recording
- **Coordinate Preview**: Watch the mouse coordinates in real-time while recording
- **Edit After Recording**: Use the visual editor to clean up or modify macros
- **Load Bar**: Add a visual progress bar to delays by setting the Load parameter

---

## 📄 License

MIT License - Feel free to use, modify, and distribute.

---

## 🤝 Contributing

Issues, suggestions, and pull requests are welcome!

---

**Built with ❤️ using PowerShell and Windows Forms**