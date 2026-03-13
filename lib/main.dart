import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pitch Count App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PitchCountForm(),
    );
  }
}

class PitchCountForm extends StatefulWidget {
  @override
  _PitchCountFormState createState() => _PitchCountFormState();
}

class _PitchCountFormState extends State<PitchCountForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  String _coachName = '';
  String _teamName = '';
  int _teamScore = 0;
  String _opponentName = '';
  int _opponentScore = 0;
  String _pitcherName = '';
  int _pitchCount = 0;

  List<String> _coachNames = [];
  List<String> _teamNames = [];
  List<String> _opponentNames = [];
  List<String> _pitcherNames = [];

  TextEditingController _coachController = TextEditingController();
  TextEditingController _teamController = TextEditingController();
  TextEditingController _teamScoreController = TextEditingController();
  TextEditingController _opponentController = TextEditingController();
  TextEditingController _opponentScoreController = TextEditingController();
  TextEditingController _pitcherController = TextEditingController();
  TextEditingController _pitchCountController = TextEditingController();
  TextEditingController _serverUrlController = TextEditingController(text: 'http://192.168.1.100:5000/add_pitch');

  @override
  void initState() {
    super.initState();
    _loadPreviousEntries();
  }

  @override
  void dispose() {
    _coachController.dispose();
    _teamController.dispose();
    _teamScoreController.dispose();
    _opponentController.dispose();
    _opponentScoreController.dispose();
    _pitcherController.dispose();
    _pitchCountController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadPreviousEntries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _coachNames = prefs.getStringList('coachNames') ?? [];
      _teamNames = prefs.getStringList('teamNames') ?? [];
      _opponentNames = prefs.getStringList('opponentNames') ?? [];
      _pitcherNames = prefs.getStringList('pitcherNames') ?? [];
    });
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    _coachName = _coachController.text;
    _teamName = _teamController.text;
    _teamScore = int.tryParse(_teamScoreController.text) ?? 0;
    _opponentName = _opponentController.text;
    _opponentScore = int.tryParse(_opponentScoreController.text) ?? 0;
    _pitcherName = _pitcherController.text;
    _pitchCount = int.tryParse(_pitchCountController.text) ?? 0;

    // Add to lists if not present
    if (!_coachNames.contains(_coachName)) _coachNames.add(_coachName);
    if (!_teamNames.contains(_teamName)) _teamNames.add(_teamName);
    if (!_opponentNames.contains(_opponentName)) _opponentNames.add(_opponentName);
    if (!_pitcherNames.contains(_pitcherName)) _pitcherNames.add(_pitcherName);

    // Save to SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('coachNames', _coachNames);
    await prefs.setStringList('teamNames', _teamNames);
    await prefs.setStringList('opponentNames', _opponentNames);
    await prefs.setStringList('pitcherNames', _pitcherNames);

    // Generate Excel
    await _sendToServer();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Entry saved and exported to Excel!')));
  }

  Future<void> _sendToServer() async {
    final url = _serverUrlController.text;
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'coach': _coachName,
          'team': _teamName,
          'teamScore': _teamScore,
          'opponent': _opponentName,
          'opponentScore': _opponentScore,
          'pitcher': _pitcherName,
          'pitchCount': _pitchCount,
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data sent to server!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send data: ${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pitch Count Input')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              // Date
              ListTile(
                title: Text("Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}"),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              // Server URL
              TextFormField(
                controller: _serverUrlController,
                decoration: InputDecoration(labelText: 'Server URL'),
                validator: (value) => value!.isEmpty ? 'Please enter server URL' : null,
              ),
              // Coach Name
              TypeAheadFormField<String>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _coachController,
                  decoration: InputDecoration(labelText: 'Coach Name'),
                ),
                suggestionsCallback: (pattern) => _coachNames.where((item) => item.toLowerCase().contains(pattern.toLowerCase())).toList(),
                itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion)),
                onSuggestionSelected: (suggestion) {
                  _coachController.text = suggestion;
                },
                validator: (value) => value!.isEmpty ? 'Please enter coach name' : null,
              ),
              // Team Name
              TypeAheadFormField<String>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _teamController,
                  decoration: InputDecoration(labelText: 'Team Name'),
                ),
                suggestionsCallback: (pattern) => _teamNames.where((item) => item.toLowerCase().contains(pattern.toLowerCase())).toList(),
                itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion)),
                onSuggestionSelected: (suggestion) {
                  _teamController.text = suggestion;
                },
                validator: (value) => value!.isEmpty ? 'Please enter team name' : null,
              ),
              // Team Score
              TextFormField(
                controller: _teamScoreController,
                decoration: InputDecoration(labelText: 'Team Score'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter team score' : null,
              ),
              // Opponent Name
              TypeAheadFormField<String>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _opponentController,
                  decoration: InputDecoration(labelText: 'Opponent Name'),
                ),
                suggestionsCallback: (pattern) => _opponentNames.where((item) => item.toLowerCase().contains(pattern.toLowerCase())).toList(),
                itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion)),
                onSuggestionSelected: (suggestion) {
                  _opponentController.text = suggestion;
                },
                validator: (value) => value!.isEmpty ? 'Please enter opponent name' : null,
              ),
              // Opponent Score
              TextFormField(
                controller: _opponentScoreController,
                decoration: InputDecoration(labelText: 'Opponent Score'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter opponent score' : null,
              ),
              // Pitcher Name
              TypeAheadFormField<String>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _pitcherController,
                  decoration: InputDecoration(labelText: 'Pitcher Name'),
                ),
                suggestionsCallback: (pattern) => _pitcherNames.where((item) => item.toLowerCase().contains(pattern.toLowerCase())).toList(),
                itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion)),
                onSuggestionSelected: (suggestion) {
                  _pitcherController.text = suggestion;
                },
                validator: (value) => value!.isEmpty ? 'Please enter pitcher name' : null,
              ),
              // Pitch Count
              TextFormField(
                controller: _pitchCountController,
                decoration: InputDecoration(labelText: 'Pitch Count'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter pitch count' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveEntry,
                child: Text('Save and Export to Excel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
