from flask import Flask, request
import openpyxl

app = Flask(__name__)

@app.route('/add_pitch', methods=['POST'])
def add_pitch():
    data = request.json
    print("Received data:", data)  # For debugging
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
    print("Data saved to pitch_counts.xlsx")
    return 'OK'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)