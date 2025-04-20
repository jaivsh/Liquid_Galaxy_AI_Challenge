import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiKMLService {
  final String _apiKey = 'AIzaSyBAe6uVh_CdRB8-Oz3pjVPGLr6r4H6SWEs';
  late GenerativeModel model;

  GeminiKMLService() {
    model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: _apiKey,
    );
  }


  Future<String> generateContent(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? 'No response generated';
    } catch (e) {
      return 'Error: $e';
    }
  }


  Future<String> generateKMLFromUserQuery(String userQuery) async {



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



    final fullPrompt = '''
$systemPrompt

User query: "$userQuery"
''';

    try {
      final content = [Content.text(fullPrompt)];
      final response = await model.generateContent(content);
      final raw = response.text ?? '';

      final cleaned = _stripCodeBlockFormatting(raw);

      final kmlRegex = RegExp(r'(<kml[\s\S]*?</kml>)');
      final match = kmlRegex.firstMatch(cleaned);
      return match?.group(0)?.trim() ?? cleaned.trim();

    } catch (e) {
      print('Error generating KML: $e');
      return '<kml></kml>';
    }
  }


  String _stripCodeBlockFormatting(String text) {
    return text.replaceAll(RegExp(r'```[a-zA-Z]*'), '').trim();
  }
}

class Location {
  final String name;
  final double latitude;
  final double longitude;
  final String description;
  final String period;

  Location({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.period,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'period': period,
    };
  }
}
