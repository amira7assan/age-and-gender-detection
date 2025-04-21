import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override

  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Age & Gender Detection',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFF1E1E2C),
        fontFamily: 'Poppins',
      ),
      home: const HomeScreen(),
    );

  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  Uint8List? _imageBytes;
  String? _gender;
  int? _age;
  bool _isLoading = false;
  final ModelApi _api = ModelApi("https://198e-104-196-139-69.ngrok-free.app/");
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    // Show a dialog with camera and gallery options
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select Image Source",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _imageSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: "Camera",
                    color: Colors.lightGreen,
                    onTap: () async {
                      Navigator.pop(context);
                      final pickedFile = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 90,
                      );
                      _processPickedImage(pickedFile);
                    },
                  ),
                  _imageSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: "Gallery",
                    color: Colors.lightGreen,
                    onTap: () async {
                      Navigator.pop(context);
                      final pickedFile = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 90,
                      );
                      _processPickedImage(pickedFile);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _imageSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Future<void> _processPickedImage(XFile? pickedFile) async {
    if (pickedFile != null) {
      _imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _gender = null;
        _age = null;
      });
    }
  }

  Future<void> _predict() async {
    if (_imageBytes == null) {
      _showSnackBar("Please select an image first", Icons.error_outline, Colors.lightGreen);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Prediction prediction = await _api.predictAgeAndGender(_imageBytes!);
      setState(() {
        _gender = prediction.gender;
        _age = prediction.age;
      });
     // _showSnackBar("susses", Icons.check_circle_outline, Colors.greenAccent);
    }catch (e) {
      _showSnackBar("Error: $e", Icons.error_outline, Colors.redAccent);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color.withOpacity(0.8),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Age & Gender Detection",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.lightGreen),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.blueGrey,
                  title: const Text("About This App", style: TextStyle(color: Colors.white)),
                  content: const Text(
                    "This app uses AI to detect age and gender from images. Results are approximate and for demonstration purposes only.",
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      child: const Text("OK", style: TextStyle(color: Colors.lightGreen)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2B2B3D),
              const Color(0xFF1A1A2E),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _animation,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_imageBytes != null)
                      Hero(
                        tag: 'selectedImage',
                        child: Container(
                          height: 250,
                          width: 250,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.memory(
                              _imageBytes!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Color(0xFF235687D3A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.face_retouching_natural,
                              size: 70,
                              color: Colors.lightGreen,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "No Image Selected",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 30),
                    _actionButton(
                      text: "Select Image",
                      icon: Icons.add_photo_alternate_outlined,
                      color: Colors.lightGreen.shade400,
                      onPressed: _pickImage,
                    ),
                    const SizedBox(height: 20),
                    _actionButton(
                      text: "Detect Age & Gender",
                      icon: Icons.analytics_outlined,
                      color: Colors.lightGreen.shade400,
                      isLoading: _isLoading,
                      onPressed: _predict,
                    ),
                    const SizedBox(height: 30),
                    if (_gender != null && _age != null)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.purpleAccent.withOpacity(0.2),
                              Colors.blueAccent.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _gender == "Male" ? Icons.male : Icons.female,
                                  color: _gender == "Male" ? Colors.blueAccent : Colors.pinkAccent,
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Gender: $_gender",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.cake_outlined,
                                  color: Colors.amberAccent,
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Age: $_age years",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _imageBytes != null ? _pickImage : null,
        backgroundColor: Colors.lightGreen,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withBlue(color.blue - 40),
          ],
        ),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: 3,
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class ModelApi {
  final String baseUrl;

  ModelApi(this.baseUrl);

  Future<Prediction> predictAgeAndGender(Uint8List imageBytes) async {
    if (imageBytes.isEmpty) {
      throw Exception("No image data provided");
    }

    var request = http.MultipartRequest("POST", Uri.parse("$baseUrl/predict"))
      ..headers.addAll({
        "ngrok-skip-browser-warning": "69420",
        "User-Agent": "Age-Gender-Detection-App",
        "Content-Type": "multipart/form-data",
        "Accept": "/",
      })
      ..files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: "image.jpg",
        contentType: MediaType("image", "jpeg"),
      ));

    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        throw Exception("Error ${response.statusCode}: $responseBody");
      }

      var data = jsonDecode(responseBody);
      if (data['success'] != true || data['predictions'] == null) {
        throw Exception(data['error'] ?? "Unknown server error");
      }

      return Prediction.fromJson(data['predictions']);
    } catch (e) {
      throw Exception("Failed to fetch predictions: $e");
    }
  }
}

class Prediction {
  final String gender;
  final int age;

  Prediction({required this.gender, required this.age});

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      gender: json['Gender'],
      age: json['Age'],
    );
  }
}