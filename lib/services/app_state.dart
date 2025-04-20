import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartssh2/dartssh2.dart';
import 'dart:io';

class AppState extends ChangeNotifier {
  // API Settings
  String _apiKey = 'AIzaSyBAe6uVh_CdRB8-Oz3pjVPGLr6r4H6SWEs'; // Your default API key

  // LG Settings
  String _lgIP = '192.168.1.100';
  int _lgPort = 22;
  String _lgUsername = 'lg';
  String _lgPassword = 'lg';
  int _lgRigs = 3;
  bool _isConnectedToLG = false;

  // SSH Client
  SSHClient? _sshClient;

  // Getters
  String get apiKey => _apiKey;
  String get lgIP => _lgIP;
  int get lgPort => _lgPort;
  String get lgUsername => _lgUsername;
  String get lgPassword => _lgPassword;
  int get lgRigs => _lgRigs;
  bool get isConnectedToLG => _isConnectedToLG;

  // Constructor loads saved settings
  AppState() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _apiKey = prefs.getString('apiKey') ?? _apiKey;
    _lgIP = prefs.getString('lgIP') ?? _lgIP;
    _lgPort = prefs.getInt('lgPort') ?? 22;
    _lgUsername = prefs.getString('lgUsername') ?? 'lg';
    _lgPassword = prefs.getString('lgPassword') ?? 'lg';
    _lgRigs = prefs.getInt('lgRigs') ?? 3;

    notifyListeners();
  }

  // Setter methods that save to SharedPreferences
  Future<void> setApiKey(String value) async {
    _apiKey = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiKey', value);
    notifyListeners();
  }

  Future<void> setLgIP(String value) async {
    _lgIP = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lgIP', value);
    notifyListeners();
  }

  Future<void> setLgPort(int value) async {
    _lgPort = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lgPort', value);
    notifyListeners();
  }

  Future<void> setLgUsername(String value) async {
    _lgUsername = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lgUsername', value);
    notifyListeners();
  }

  Future<void> setLgPassword(String value) async {
    _lgPassword = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lgPassword', value);
    notifyListeners();
  }

  Future<void> setLgRigs(int value) async {
    _lgRigs = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lgRigs', value);
    notifyListeners();
  }

  // SSH Connection methods
  Future<bool> connectToLG() async {
    if (_lgIP.isEmpty) {
      print('Cannot connect: IP address is empty');
      return false;
    }

    try {
      // Disconnect first if already connected
      if (_sshClient != null) {
        await disconnectFromLG();
      }

      // Create connection
      final socket = await SSHSocket.connect(_lgIP, _lgPort);

      _sshClient = SSHClient(
        socket,
        username: _lgUsername,
        onPasswordRequest: () => _lgPassword,
      );

      // Test connection with a simple command
      final testResult = await _sshClient!.run('echo "Connection test"');
      final output = String.fromCharCodes(testResult);

      if (output.contains('Connection test')) {
        _isConnectedToLG = true;
        notifyListeners();
        return true;
      } else {
        _isConnectedToLG = false;
        notifyListeners();
        return false;
      }
    } on SocketException catch (e) {
      print('Socket error: $e');
      _isConnectedToLG = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Connection error: $e');
      _isConnectedToLG = false;
      notifyListeners();
      return false;
    }
  }
  Future<void> disconnectFromLG() async {
    if (_sshClient != null) {
      _sshClient!.close(); // Removed 'await'
      _sshClient = null;
    }
    _isConnectedToLG = false;
    notifyListeners();
  }


  // Send KML to Liquid Galaxy
  Future<bool> sendKmlToLG(String kmlContent) async {
    if (!_isConnectedToLG || _sshClient == null) {
      print('Cannot send KML: Not connected to Liquid Galaxy');
      return false;
    }

    try {
      // Step 1: Create temporary file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final kmlFileName = 'temporalexplorer_$timestamp.kml';

      // Step 2: Write KML content to a temporary file in the LG system
      final sftp = await _sshClient!.sftp();
      final file = await sftp.open('/tmp/$kmlFileName',
          mode: SftpFileOpenMode.create | SftpFileOpenMode.write);

      await file.write(kmlContent.codeUnits as Stream<Uint8List>);
      await file.close();

      // Step 3: Send commands to load the KML file
      // First clean any existing tours/kml files
      await _sshClient!.run('echo "floytour=false" > /tmp/query.txt');
      await _sshClient!.run('echo "exittour=true" > /tmp/query.txt');

      // Wait for the tour to exit
      await Future.delayed(const Duration(seconds: 1));

      // Load the new KML file
      final loadCommand = 'echo "playtour=loadkml=/tmp/$kmlFileName" > /tmp/query.txt';
      await _sshClient!.run(loadCommand);

      return true;
    } catch (e) {
      print('Error sending KML to LG: $e');
      return false;
    }
  }

  final systemPrompt = """
You are a KML generator for Google Earth and Liquid Galaxy systems. Only output valid XML that begins with <kml> and ends with </kml>. Do not include markdown, explanations, or commentary. Generate Google Earth KML with the namespace: xmlns="http://www.opengis.net/kml/2.2" and xmlns:gx="http://www.google.com/kml/ext/2.2" — no other namespaces.

Your primary goal is to produce a rich, immersive, and visually stunning <gx:Tour> experience whenever the user asks for a “tour.” Follow these requirements *exactly*:

1.  **Overall Structure**  
    - Wrap everything in a single `<kml><Document>…</Document></kml>` block.  
    - Declare shared `<Style>` blocks at the top (for icons, balloons, lines) and reference them via `<styleUrl>`.  

2.  **Tour Element**  
    - Include a `<gx:Tour>` with one `<gx:Playlist>`.  
    - For each stop (3–10 locations, based on the query):  
      a. `<gx:FlyTo>` with:  
         - `<gx:duration>` (e.g. 5–8s)  
         - `<gx:flyToMode>` (`smooth` or `bounce`)  
         - A `<LookAt>` or `<Camera>` child specifying `<longitude>`, `<latitude>`, `<altitude>`, `<heading>`, `<tilt>`, and `<range>`.  
      b. Immediately after, a `<gx:AnimatedUpdate>` that sets `<gx:balloonVisibility>1</gx:balloonVisibility>` for that placemark.  
      c. A `<gx:Wait>` (5–10 s) so viewers can absorb the location.  
      d. *(Optional)* `<gx:TourControl><gx:playMode>pause</gx:playMode></gx:TourControl>` to allow manual exploration.  

3.  **Placemarks & BalloonStyles**  
    - Each stop must be a `<Placemark>` with:  
      - `<name>` and `<description>` (1–3 lines of engaging historical/cultural context).  
      - `<Point><coordinates>longitude,latitude,0</coordinates></Point>`.  
      - `<styleUrl>` referencing a shared `<BalloonStyle>` that:  
        * Controls text size, fonts, background colors.  
        * Does not embed any image in description balloon.
        * Can include `<Link>`s or `<p>` tags for structure.  

4.  **Cinematic Camera Choreography**  
    - **Tilt**: 40°–60° for architectural depth.  
    - **Range**: Vary between high (context) and low (detail).  
    - **Heading**: Angle the camera to showcase façades or coastlines.  
    - **Curved Paths**: Chain overlapping `<gx:FlyTo>` segments for gentle arcs.  

5.  **Flight Modes & Timing**  
    - Use `<gx:flyToMode>smooth</gx:flyToMode>` for sweeping transitions; `bounce` for dramatic “landings.”  
    - Balance durations: e.g., fly 6s → wait 8s → fly 4s → wait 6s.  
    - Insert `<gx:TourControl>` sparingly to break the automation.  

6.  **Animated Updates & Sequencing**  
    - Use `<gx:AnimatedUpdate>` + `<gx:duration>` to handle balloon toggles, icon changes, or overlay additions mid‑tour.  
    - Always follow each AnimatedUpdate with a matching `<gx:Wait>`.  

7.  **Sound & Narration (Optional)**  
    - At tour start, add `<gx:SoundCue><href>…</href></gx:SoundCue>`.  
    - After each clip, use a `<gx:Wait>` equal to the audio length to sync visuals and narration.  

8.  **Performance & Scalability**  
    - For more than 20 stops, split into separate KML files loaded via `<NetworkLink>`.  
    - Use `<Region>` extents so only placemarks within view are loaded on Liquid Galaxy.  

9.  **Prompt‑Engineering Guidelines**  
    - Instruct: “Pause X seconds at each placemark(so that user can see where they are, and if required even pause if user tells so at each placemark and then when user resumes tour would function), open balloon for Y seconds, then smoothly fly to the next with tilt=Z°.”  
    - Ask for “cinematic, story‑driven sequences with dynamic camera angles and timed information balloons.”  
    - Limit to “3–7 iconic stops” to maintain clarity.  
    - Embed “one high‑resolution image per location, sized ~200×200 px.”  

10. **Content Selection**  
    - Based strictly on the user’s query, select the most relevant historical or cultural locations.  
    - Provide real-world, precise coordinates and accurate dates/events.  
    - Include brief, engaging narratives or personality highlights in each placemark’s description.  

**Now**, generate the complete KML tour XML—paused, ballooned, and cinematic—ready to drop into Google Earth or Liquid Galaxy. Only return the finished KML block.  
""";

  @override
  void dispose() {
    disconnectFromLG();
    super.dispose();
  }
}