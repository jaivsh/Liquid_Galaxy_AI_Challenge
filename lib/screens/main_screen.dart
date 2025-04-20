import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../services/app_state.dart';
import '../services/gemini_service.dart';
import '../services/tts_service.dart';
import '../services/voice_input_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _queryController = TextEditingController();
  final TTSService _ttsService = TTSService();
  final VoiceInputService _voiceInputService = VoiceInputService();
  String _response = '';
  bool _isLoading = false;
  bool _showKML = false;
  bool _isListening = false;
  bool _isVisualizing = false;

  @override
  void initState() {
    super.initState();
    _initializeVoiceInput();
  }

  Future<void> _initializeVoiceInput() async {
    await _voiceInputService.initialize();
  }

  void _visualizeKML() async {
    final appState = Provider.of<AppState>(context, listen: false);

    if (!appState.isConnectedToLG) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected to Liquid Galaxy. Please connect in Settings.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVisualizing = true;
    });

    try {
      final success = await appState.sendKmlToLG(_response);

      setState(() {
        _isVisualizing = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KML visualization sent to Liquid Galaxy'),
            backgroundColor: Colors.green,
          ),
        );
        _ttsService.speak("Visualization sent to Liquid Galaxy.");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send visualization to Liquid Galaxy'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isVisualizing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _processQuery() async {
    final query = _queryController.text;
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _response = '';
    });

    try {
      final geminiService = GeminiKMLService();
      final result = await geminiService.generateKMLFromUserQuery(query);

      setState(() {
        _response = result;
        _isLoading = false;
      });

      final appState = Provider.of<AppState>(context, listen: false);

      if (appState.isConnectedToLG) {
        // TODO: Send the KML to LG system via SSH or API
        // Example: await LGConnectionService.sendKML(result);
      }

      _ttsService.speak("Your KML file is ready.");
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _response)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('KML copied to clipboard')),
      );
    });
  }


  Future<void> _startVoiceInput() async {
    setState(() {
      _isListening = true;
    });

    await _voiceInputService.startListening(
      onResult: (text) {
        setState(() {
          _queryController.text = text;
        });
      },
      onListeningComplete: () {
        setState(() {
          _isListening = false;
        });
      },
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Temporal Explorer'),
        actions: [
          IconButton(
            icon: Icon(
              appState.isConnectedToLG ? Icons.link : Icons.link_off,
              color: appState.isConnectedToLG ? Colors.green : Colors.red,
            ),
            onPressed: appState.isConnectedToLG
                ? appState.disconnectFromLG
                : appState.connectToLG,
            tooltip: appState.isConnectedToLG
                ? 'Disconnect from Liquid Galaxy'
                : 'Connect to Liquid Galaxy',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.pushNamed(context, '/settings');
              } else if (value == 'about') {
                Navigator.pushNamed(context, '/about');
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem<String>(
                value: 'about',
                child: Text('About'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Query input section
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                labelText: 'Ask about historical or cultural places',
                hintText: 'E.g., "Show me the evolution of temples in Southeast Asia"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(_isListening ? Icons.mic_none : Icons.mic),
                  color: _isListening ? Colors.red : null,
                  onPressed: _startVoiceInput,
                  tooltip: 'Voice Input',
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _processQuery,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Explore'),
            ),
            const SizedBox(height: 24),

            // Results section
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_response.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Response Generated',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Toggle switch for showing KML
                          Row(
                            children: [
                              const Text('Show KML Code'),
                              Switch(
                                value: _showKML,
                                onChanged: (value) {
                                  setState(() {
                                    _showKML = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Visualize Button - Moved here, before the KML section
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isVisualizing ? null : _visualizeKML,
                          icon: _isVisualizing
                              ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(Icons.public),
                          label: Text(_isVisualizing ? 'Sending to Liquid Galaxy...' : 'Visualize on Liquid Galaxy'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // KML display section
                      if (_showKML)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'KML Code',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.content_copy),
                                    onPressed: _copyToClipboard,
                                    tooltip: 'Copy KML',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _response,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      if (!_showKML)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'KML file generated successfully. Toggle "Show KML Code" to view the actual code.',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _response.isNotEmpty
          ? FloatingActionButton(
        onPressed: () => _ttsService.speak("Your KML file is generated."),
        tooltip: 'Read Aloud',
        child: const Icon(Icons.volume_up),
      )
          : null,
    );
  }
}