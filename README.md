# Pitch Count App

A Flutter app for easily inputting pitch counts from baseball games on mobile devices. Data is sent to a server on the host computer and appended to an Excel spreadsheet.

## Features
- Input game details: Date, Coach Name, Team Name, Team Score, Opponent Name, Opponent Score, Pitcher Name, Pitch Count
- Dropdown suggestions for previously entered names (Coach, Team, Opponent, Pitcher)
- Date picker for game date
- Sends data to a server running on the host computer
- Server appends data to `pitch_counts.xlsx` on the host

## Requirements
- Flutter SDK installed and on your PATH
- For Android: Android device or emulator
- For iOS: Mac with Xcode installed
- Python installed on host computer (for server)

## Setup Server on Host Computer
1. Install Python (if not already).
2. Install openpyxl: `pip install flask openpyxl`
3. Create `server.py` with the following code:

```python
from flask import Flask, request
import openpyxl

app = Flask(__name__)

@app.route('/add_pitch', methods=['POST'])
def add_pitch():
    data = request.json
    # Load or create Excel
    try:
        wb = openpyxl.load_workbook('pitch_counts.xlsx')
        sheet = wb['Pitch Counts']
    except:
        wb = openpyxl.Workbook()
        sheet = wb.active
        sheet.title = 'Pitch Counts'
        sheet.append(['Date', 'Coach Name', 'Team Name', 'Team Score', 'Opponent Name', 'Opponent Score', 'Pitcher Name', 'Pitch Count'])
    sheet.append([data['date'], data['coach'], data['team'], data['teamScore'], data['opponent'], data['opponentScore'], data['pitcher'], data['pitchCount']])
    wb.save('pitch_counts.xlsx')
    return 'OK'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

4. Run the server: `python server.py`
5. Find host IP: Run `ipconfig` in Command Prompt, note the IPv4 address (e.g., 192.168.1.100)
6. In the app, set Server URL to `http://<host_ip>:5000/add_pitch`

## Run App
```bash
cd pitch_count_app
flutter pub get
flutter run
```

## Check Setup
```bash
flutter doctor
```

The spreadsheet `pitch_counts.xlsx` will be created/updated in the same directory as `server.py` on the host computer.
