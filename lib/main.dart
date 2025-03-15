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
  // Mode selection
  bool _isMultiMode = false;

  // Single image mode variables
  Uint8List? _imageBytes;
  String? _gender;
  int? _age;

  // Multi image mode variables
  List<Uint8List> _multiImageBytes = [];
  List<Prediction> _predictions = [];

  bool _isLoading = false;
  final ModelApi _api = ModelApi("https://a233-104-196-210-26.ngrok-free.app/");
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

  Future<void> _pickImage({bool multi = false}) async {
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
                  //_imageSourceOption(
                   // icon: Icons.camera_alt_rounded,
                   // label: "Camera",
                   // color: Colors.lightGreen,
                   // onTap: () async {
                    //  Navigator.pop(context);
                      //if (multi) {
                        // Camera can only take one image at a time
                        //final pickedFile = await picker.pickImage(
                          //source: ImageSource.camera,
                         // imageQuality: 90,
                       // );
                       // if (pickedFile != null) {
                        //  _processMultiPickedImage([pickedFile]);
                      //  }
                    //  } else {
                    //    final pickedFile = await picker.pickImage(
                  //        source: ImageSource.camera,
                        //  imageQuality: 90,
                      //  );
                    //    _processSinglePickedImage(pickedFile);
                  //    }
                //    },
              //    ),
                  _imageSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: "Gallery",
                    color: Colors.lightGreen,
                    onTap: () async {
                      Navigator.pop(context);
                      if (multi) {
                        final pickedFiles = await picker.pickMultiImage(
                          imageQuality: 90,
                        );
                        _processMultiPickedImage(pickedFiles);
                      } else {
                        final pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 90,
                        );
                        _processSinglePickedImage(pickedFile);
                      }
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

  Future<void> _processSinglePickedImage(XFile? pickedFile) async {
    if (pickedFile != null) {
      _imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _gender = null;
        _age = null;
      });
    }
  }

  Future<void> _processMultiPickedImage(List<XFile> pickedFiles) async {
    if (pickedFiles.isNotEmpty) {
      List<Uint8List> newImages = [];
      for (var file in pickedFiles) {
        newImages.add(await file.readAsBytes());
      }

      setState(() {
        _multiImageBytes.addAll(newImages);
      });
    }
  }

  Future<void> _predict() async {
    if (_isMultiMode) {
      await _predictMultiple();
    } else {
      await _predictSingle();
    }
  }

  Future<void> _predictSingle() async {
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
    } catch (e) {
      _showSnackBar("Error: $e", Icons.error_outline, Colors.redAccent);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _predictMultiple() async {
    if (_multiImageBytes.isEmpty) {
      _showSnackBar("Please select at least one image", Icons.error_outline, Colors.lightGreen);
      return;
    }

    setState(() {
      _isLoading = true;
      _predictions = [];
    });

    try {
      List<Prediction> results = [];

      for (var imageBytes in _multiImageBytes) {
        Prediction prediction = await _api.predictAgeAndGender(imageBytes);
        results.add(prediction);
      }

      setState(() {
        _predictions = results;
      });

      // Navigate to report screen
      if (_predictions.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportScreen(
              images: _multiImageBytes,
              predictions: _predictions,
            ),
          ),
        );
      }
    } catch (e) {
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

  void _toggleMode() {
    setState(() {
      _isMultiMode = !_isMultiMode;
      // Reset data when switching modes
      if (_isMultiMode) {
        _multiImageBytes = [];
        _predictions = [];
      } else {
        _imageBytes = null;
        _gender = null;
        _age = null;
      }
    });
  }

  void _removeMultiImage(int index) {
    setState(() {
      _multiImageBytes.removeAt(index);
    });
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
            icon: Icon(
              _isMultiMode ? Icons.person : Icons.groups,
              color: Colors.lightGreen,
            ),
            onPressed: _toggleMode,
            tooltip: _isMultiMode ? "Switch to Single Mode" : "Switch to Multi Mode",
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.lightGreen),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF2B2B3D),
                  title: const Text("About This App", style: TextStyle(color: Colors.white)),
                  content: const Text(
                    "This app uses AI to detect age and gender from images. Single mode analyzes one image, while Multi mode generates a report from multiple images. Results are approximate and for demonstration purposes only.",
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2B2B3D),
              Color(0xFF1A1A2E),
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
                    // Mode indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.lightGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        _isMultiMode ? "Multi-Image Mode" : "Single-Image Mode",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Single image mode
                    if (!_isMultiMode) ...[
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
                            color: const Color(0xFF356D3A),
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
                        onPressed: () => _pickImage(multi: false),
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

                    // Multi image mode
                    if (_isMultiMode) ...[
                      if (_multiImageBytes.isEmpty)
                        Container(
                          height: 200,
                          width: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFF356D3A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.photo_library,
                                size: 70,
                                color: Colors.lightGreen,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "No Images Selected",
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "${_multiImageBytes.length} ${_multiImageBytes.length == 1 ? 'Image' : 'Images'} Selected",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.black12,
                              ),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _multiImageBytes.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 150,
                                        margin: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 5,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.memory(
                                            _multiImageBytes[index],
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: GestureDetector(
                                          onTap: () => _removeMultiImage(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(5),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 30),
                      _actionButton(
                        text: "Add Images",
                        icon: Icons.add_photo_alternate_outlined,
                        color: Colors.lightGreen.shade400,
                        onPressed: () => _pickImage(multi: true),
                      ),
                      const SizedBox(height: 20),
                      _actionButton(
                        text: "Generate Report",
                        icon: Icons.analytics_outlined,
                        color: Colors.lightGreen.shade400,
                        isLoading: _isLoading,
                        onPressed: _predict,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (_isMultiMode && _multiImageBytes.isNotEmpty) || (!_isMultiMode && _imageBytes != null)
            ? () {
          if (_isMultiMode) {
            setState(() {
              _multiImageBytes = [];
              _predictions = [];
            });
          } else {
            setState(() {
              _imageBytes = null;
              _gender = null;
              _age = null;
            });
          }
        }
            : null,
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

class ReportScreen extends StatelessWidget {
  final List<Uint8List> images;
  final List<Prediction> predictions;

  const ReportScreen({
    super.key,
    required this.images,
    required this.predictions,
  });

  Map<String, int> _getGenderDistribution() {
    Map<String, int> distribution = {'Male': 0, 'Female': 0};
    for (var prediction in predictions) {
      distribution[prediction.gender] = (distribution[prediction.gender] ?? 0) + 1;
    }
    return distribution;
  }

  Map<String, int> _getAgeGroupDistribution() {
    Map<String, int> distribution = {
      '0-12': 0,
      '13-19': 0,
      '20-29': 0,
      '30-39': 0,
      '40-49': 0,
      '50-59': 0,
      '60+': 0,
    };

    for (var prediction in predictions) {
      String ageGroup;
      if (prediction.age <= 12) {
        ageGroup = '0-12';
      } else if (prediction.age <= 19) {
        ageGroup = '13-19';
      } else if (prediction.age <= 29) {
        ageGroup = '20-29';
      } else if (prediction.age <= 39) {
        ageGroup = '30-39';
      } else if (prediction.age <= 49) {
        ageGroup = '40-49';
      } else if (prediction.age <= 59) {
        ageGroup = '50-59';
      } else {
        ageGroup = '60+';
      }
      distribution[ageGroup] = (distribution[ageGroup] ?? 0) + 1;
    }
    return distribution;
  }

  double _getAverageAge() {
    if (predictions.isEmpty) return 0;
    int total = predictions.fold(0, (sum, prediction) => sum + prediction.age);
    return total / predictions.length;
  }

  @override
  Widget build(BuildContext context) {
    final genderDistribution = _getGenderDistribution();
    final ageGroupDistribution = _getAgeGroupDistribution();
    final avgAge = _getAverageAge();

    return Scaffold(
        appBar: AppBar(
        title: const Text('Analysis Report', style: TextStyle(color: Colors.white)),
    backgroundColor: const Color(0xFF2B2B3D),
    iconTheme: const IconThemeData(color: Colors.white),
    actions: [
    IconButton(
    icon: const Icon(Icons.share, color: Colors.lightGreen),
    onPressed: () {
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Share functionality would go here')),
    );
    },
    ),
    ],
    ),
    body: Container(
    decoration: const BoxDecoration(
    gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
    Color(0xFF2B2B3D),
    Color(0xFF1A1A2E),
    ],
    ),
    ),
    child: SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    // Summary card
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
    ),
    child: Column(
    children: [
    const Text(
    'Summary',
    style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    ),
    ),
    const SizedBox(height: 15),
    _summaryItem(
    Icons.photo_library,
    'Total Images',
    '${images.length}',
    Colors.lightGreen,
    ),
    const Divider(color: Colors.white24),
    _summaryItem(
    Icons.people_alt,
    'Gender Distribution',
    '${genderDistribution['Male']} Male, ${genderDistribution['Female']} Female',
    Colors.lightBlue,
    ),
    const Divider(color: Colors.white24),
    _summaryItem(
    Icons.date_range,
    'Average Age',
    '${avgAge.toStringAsFixed(1)} years',
    Colors.amber,
    ),
    ],
    ),
    ),

    const SizedBox(height: 30),

    // Age group distribution
    const Text(
    'Age Group Distribution',
    style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    ),
    ),
    const SizedBox(height: 15),
    Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
    color: Colors.black12,
    borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
    children: ageGroupDistribution.entries.map((entry) {
    final percentage = predictions.isEmpty
    ? 0.0
        : (entry.value / predictions.length * 100);

    return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    Text(
    entry.key,
    style: const TextStyle(
    color: Colors.white70,
    fontSize: 16,
    ),
    ),
    Text(
    '${entry.value} (${percentage.toStringAsFixed(1)}%)',
    style: const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 16,
    ),
    ),
    ],
    ),
    const SizedBox(height: 5),
    LinearProgressIndicator(
    value: predictions.isEmpty ? 0 : entry.value / predictions.length,
    backgroundColor: Colors.grey.shade800,
    valueColor: AlwaysStoppedAnimation<Color>(
    HSLColor.fromAHSL(
    1.0,
    (entry.key == '0-12') ? 140.0 :
    (entry.key == '13-19') ? 160.0 :
    (entry.key == '20-29') ? 180.0 :
    (entry.key == '30-39') ? 200.0 :
    (entry.key == '40-49') ? 220.0 :
    (entry.key == '50-59') ? 240.0 : 260.0,
    0.7,
    0.5,
    ).toColor(),
    ),
    minHeight: 8,
    borderRadius: BorderRadius.circular(10),
    ),
      const SizedBox(height: 10),
    ],
    ),
    );
    }).toList(),
    ),
    ),

      const SizedBox(height: 30),

      // Detailed results
      const Text(
        'Detailed Results',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 15),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(15),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              title: Text(
                'Person ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${predictions[index].gender}, ${predictions[index].age} years',
                style: const TextStyle(color: Colors.white70),
              ),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    images[index],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Container(
                        width: 120,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            images[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _detailItem(
                              predictions[index].gender == "Male" ? Icons.male : Icons.female,
                              "Gender",
                              predictions[index].gender,
                              predictions[index].gender == "Male" ? Colors.blueAccent : Colors.pinkAccent,
                            ),
                            const SizedBox(height: 15),
                            _detailItem(
                              Icons.cake_outlined,
                              "Age",
                              "${predictions[index].age} years",
                              Colors.amberAccent,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),

      const SizedBox(height: 20),

      Center(
        child: Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.lightGreen.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.lightGreen,
                Colors.lightGreen.withBlue(Colors.lightGreen.blue - 40),
              ],
            ),
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back),
                SizedBox(width: 10),
                Text(
                  "Back to Images",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
    ),
    ),
    ),
    );
  }

  Widget _summaryItem(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
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