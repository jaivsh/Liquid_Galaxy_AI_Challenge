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
  late TextEditingController _lgUsernameController;
  late TextEditingController _lgPasswordController;
  late TextEditingController _lgRigsController;

  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    _apiKeyController = TextEditingController(text: appState.apiKey);
    _lgIpController = TextEditingController(text: appState.lgIP);
    _lgPortController = TextEditingController(text: appState.lgPort.toString());
    _lgUsernameController = TextEditingController(text: appState.lgUsername);
    _lgPasswordController = TextEditingController(text: appState.lgPassword);
    _lgRigsController = TextEditingController(text: appState.lgRigs.toString());
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _lgIpController.dispose();
    _lgPortController.dispose();
    _lgUsernameController.dispose();
    _lgPasswordController.dispose();
    _lgRigsController.dispose();
    super.dispose();
  }

  Future<void> _attemptConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Save the form data first
    _formKey.currentState!.save();

    setState(() {
      _isConnecting = true;
    });

    final appState = Provider.of<AppState>(context, listen: false);
    final success = await appState.connectToLG();

    setState(() {
      _isConnecting = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Connected to Liquid Galaxy successfully'
            : 'Failed to connect to Liquid Galaxy'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (appState.isConnectedToLG)
            Icon(
              Icons.check_circle,
              color: Colors.green,
            ),
        ],
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
                prefixIcon: Icon(Icons.computer),
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
                labelText: 'SSH Port',
                hintText: 'E.g., 22',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.settings_ethernet),
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
            TextFormField(
              controller: _lgUsernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'E.g., lg',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a username';
                }
                return null;
              },
              onSaved: (value) {
                if (value != null) {
                  appState.setLgUsername(value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lgPasswordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                return null;
              },
              onSaved: (value) {
                if (value != null) {
                  appState.setLgPassword(value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lgRigsController,
              decoration: const InputDecoration(
                labelText: 'Number of Rigs',
                hintText: 'E.g., 3',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.memory),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter number of rigs';
                }
                final rigs = int.tryParse(value);
                if (rigs == null || rigs <= 0) {
                  return 'Please enter a valid number of rigs';
                }
                return null;
              },
              onSaved: (value) {
                if (value != null) {
                  appState.setLgRigs(int.parse(value));
                }
              },
            ),
            const SizedBox(height: 24),
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
            ElevatedButton.icon(
              onPressed: _isConnecting || appState.isConnectedToLG
                  ? appState.disconnectFromLG
                  : _attemptConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: appState.isConnectedToLG
                    ? Colors.red
                    : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(
                appState.isConnectedToLG ? Icons.link_off : Icons.link,
              ),
              label: _isConnecting
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('Connecting...'),
                ],
              )
                  : Text(
                appState.isConnectedToLG
                    ? 'Disconnect from Liquid Galaxy'
                    : 'Connect to Liquid Galaxy',
              ),
            ),
            if (appState.isConnectedToLG) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Connected to Liquid Galaxy at ${appState.lgIP}',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}