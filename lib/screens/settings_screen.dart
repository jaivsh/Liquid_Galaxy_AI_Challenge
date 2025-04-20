import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _apiKeyController;
  late TextEditingController _lgIpController;
  late TextEditingController _lgPortController;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _apiKeyController = TextEditingController(text: appState.apiKey);
    _lgIpController = TextEditingController(text: appState.lgIP);
    _lgPortController = TextEditingController(text: appState.lgPort.toString());
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _lgIpController.dispose();
    _lgPortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // API Settings Section
            const Text(
              'API Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'Enter your Gemini API Key',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an API Key';
                }
                return null;
              },
              onSaved: (value) {
                if (value != null) {
                  appState.setApiKey(value);
                }
              },
            ),
            const SizedBox(height: 24),

            // Liquid Galaxy Connection Settings
            const Text(
              'Liquid Galaxy Connection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _lgIpController,
              decoration: const InputDecoration(
                labelText: 'Liquid Galaxy IP Address',
                hintText: 'E.g., 192.168.1.100',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an IP Address';
                }
                // Simple IP validation
                final ipRegExp = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                if (!ipRegExp.hasMatch(value)) {
                  return 'Please enter a valid IP address';
                }
                return null;
              },
              onSaved: (value) {
                if (value != null) {
                  appState.setLgIP(value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lgPortController,
              decoration: const InputDecoration(
                labelText: 'Liquid Galaxy Port',
                hintText: 'E.g., 8080',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a port number';
                }
                final port = int.tryParse(value);
                if (port == null || port <= 0 || port > 65535) {
                  return 'Please enter a valid port number (1-65535)';
                }
                return null;
              },
              onSaved: (value) {
                if (value != null) {
                  appState.setLgPort(int.parse(value));
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings saved')),
                  );
                }
              },
              child: const Text('Save Settings'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: appState.isConnectedToLG
                  ? appState.disconnectFromLG
                  : appState.connectToLG,
              style: ElevatedButton.styleFrom(
                backgroundColor: appState.isConnectedToLG
                    ? Colors.red
                    : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(
                appState.isConnectedToLG
                    ? 'Disconnect from Liquid Galaxy'
                    : 'Connect to Liquid Galaxy',
              ),
            ),
          ],
        ),
      ),
    );
  }
}