import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/parakh_colors.dart';

class AnimalProfileScreen extends StatefulWidget {
  const AnimalProfileScreen({required this.isHindi, super.key});

  final bool isHindi;

  @override
  State<AnimalProfileScreen> createState() => _AnimalProfileScreenState();
}

class _AnimalProfileScreenState extends State<AnimalProfileScreen> {
  String _selectedAnimal = 'cow';
  String? _selectedBreed;
  bool _isSaving = false;
  String _selectedGoal = 'maintenance';
  String _selectedStage = 'lactating';

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _milkYieldController = TextEditingController();
  final TextEditingController _milkFatController = TextEditingController();

  final List<Map<String, String>> _cowBreeds = [
    {
      'id': 'gir',
      'english': 'Gir',
      'hindi': 'गिर',
      'image': 'assets/images/breeds/cows/gir.jpg',
    },
    {
      'id': 'sahiwal',
      'english': 'Sahiwal',
      'hindi': 'साहीवाल',
      'image': 'assets/images/breeds/cows/sahiwal.jpg',
    },
    {
      'id': 'tharparkar',
      'english': 'Tharparkar',
      'hindi': 'थारपारकर',
      'image': 'assets/images/breeds/cows/tharparkar.jpg',
    },
    {
      'id': 'rathi',
      'english': 'Rathi',
      'hindi': 'राठी',
      'image': 'assets/images/breeds/cows/rathi.jpg',
    },
    {
      'id': 'hf',
      'english': 'Holstein Friesian',
      'hindi': 'होल्स्टीन फ्रीजियन',
      'image': 'assets/images/breeds/cows/hf.jpg',
    },
    {
      'id': 'jersey',
      'english': 'Jersey',
      'hindi': 'जर्सी',
      'image': 'assets/images/breeds/cows/jersey.jpg',
    },
    {
      'id': 'cow_unknown',
      'english': 'Other / Not sure',
      'hindi': 'अन्य / पता नहीं',
      'image': '',
    },
  ];

  final List<Map<String, String>> _buffaloBreeds = [
    {
      'id': 'murrah',
      'english': 'Murrah',
      'hindi': 'मुर्रा',
      'image': 'assets/images/breeds/buffaloes/murrah.jpg',
    },
    {
      'id': 'mehsana',
      'english': 'Mehsana',
      'hindi': 'मेहसाना',
      'image': 'assets/images/breeds/buffaloes/mehsana.jpg',
    },
    {
      'id': 'jaffarabadi',
      'english': 'Jaffarabadi',
      'hindi': 'जाफराबादी',
      'image': 'assets/images/breeds/buffaloes/jaffarabadi.jpg',
    },
    {
      'id': 'surti',
      'english': 'Surti',
      'hindi': 'सूरती',
      'image': 'assets/images/breeds/buffaloes/surti.jpg',
    },
    {
      'id': 'nili_ravi',
      'english': 'Nili-Ravi',
      'hindi': 'नीली-रावी',
      'image': 'assets/images/breeds/buffaloes/nili_ravi.jpg',
    },
    {
      'id': 'bhadawari',
      'english': 'Bhadawari',
      'hindi': 'भदावरी',
      'image': 'assets/images/breeds/buffaloes/bhadawari.jpg',
    },
    {
      'id': 'buffalo_unknown',
      'english': 'Other / Not sure',
      'hindi': 'अन्य / पता नहीं',
      'image': '',
    },
  ];

  String _text(String english, String hindi) {
    return widget.isHindi ? hindi : english;
  }

  List<Map<String, String>> get _visibleBreeds {
    return _selectedAnimal == 'cow' ? _cowBreeds : _buffaloBreeds;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _milkYieldController.dispose();
    _milkFatController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final preferences = await SharedPreferences.getInstance();

    final animal = preferences.getString('animalType') ?? 'cow';
    final breed = preferences.getString('animalBreed');
    final stage = preferences.getString('animalStage') ?? 'lactating';
    final goal = preferences.getString('productionGoal') ?? 'maintenance';
    final weight = preferences.getString('animalWeight') ?? '';
    final milkYield = preferences.getString('dailyMilkYield') ?? '';
    final milkFat = preferences.getString('milkFatPercent') ?? '';
await preferences.setBool('animalProfileCompleted', true);
    if (!mounted) return;

    _weightController.text = weight;
    _milkYieldController.text = milkYield;
    _milkFatController.text = milkFat;

    setState(() {
      _selectedAnimal = animal;
      _selectedBreed = breed;
      _selectedStage = stage;
      _selectedGoal = goal;
    });
  }

  Future<void> _saveProfile() async {
    if (_selectedBreed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Please select a breed or choose Not sure.',
              'कृपया नस्ल चुनें या पता नहीं विकल्प चुनें।',
            ),
          ),
        ),
      );
      return;
    }

    final weight = double.tryParse(_weightController.text.trim());

    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Please enter a valid approximate weight.',
              'कृपया सही अनुमानित वजन दर्ज करें।',
            ),
          ),
        ),
      );
      return;
    }

    if (_selectedStage == 'lactating') {
      final milkYield = double.tryParse(_milkYieldController.text.trim());
      final milkFat = double.tryParse(_milkFatController.text.trim());

      if (milkYield == null ||
          milkYield <= 0 ||
          milkFat == null ||
          milkFat <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _text(
                'Please enter valid milk yield and milk fat values.',
                'कृपया सही दूध उत्पादन और दूध वसा मान दर्ज करें।',
              ),
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString('animalType', _selectedAnimal);
    await preferences.setString('animalBreed', _selectedBreed!);
    await preferences.setString('animalStage', _selectedStage);
    await preferences.setString('productionGoal', _selectedGoal);
    await preferences.setString('animalWeight', _weightController.text.trim());
    await preferences.setString(
      'dailyMilkYield',
      _milkYieldController.text.trim(),
    );
    await preferences.setString(
      'milkFatPercent',
      _milkFatController.text.trim(),
    );

    if (!mounted) return;
await preferences.setBool('animalProfileCompleted', true);
    Navigator.of(context).pop(true);
  }

  void _selectAnimal(String animal) {
    setState(() {
      _selectedAnimal = animal;
      _selectedBreed = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F2),
        surfaceTintColor: Colors.transparent,
        title: Text(
          _text('Animal profile', 'पशु प्रोफाइल'),
          style: const TextStyle(
            color: Color(0xFF1B2B21),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              children: [
                Text(
                  _text('Select your animal', 'अपना पशु चुनें'),
                  style: const TextStyle(
                    color: Color(0xFF1B2B21),
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _text(
                    'This helps Parakh provide goal-specific screening guidance.',
                    'इससे परख लक्ष्य के अनुसार जाँच संबंधी मार्गदर्शन देता है।',
                  ),
                  style: const TextStyle(
                    color: Color(0xFF748078),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _animalCard(
                        animal: 'cow',
                        title: _text('Cow', 'गाय'),
                        imagePath: 'assets/images/animals/cow.png',
                        fallbackIcon: Icons.agriculture_rounded,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: _animalCard(
                        animal: 'buffalo',
                        title: _text('Buffalo', 'भैंस'),
                        imagePath: 'assets/images/animals/buffalo.png',
                        fallbackIcon: Icons.pets_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 27),
                Text(
                  _text('Select breed', 'नस्ल चुनें'),
                  style: const TextStyle(
                    color: Color(0xFF1B2B21),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _text(
                    'Choose Not sure if you do not know the breed.',
                    'यदि नस्ल नहीं जानते हैं तो पता नहीं चुनें।',
                  ),
                  style: const TextStyle(
                    color: Color(0xFF748078),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _visibleBreeds.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 13,
                    mainAxisSpacing: 13,
                    mainAxisExtent: 155,
                  ),
                  itemBuilder: (context, index) {
                    return _breedCard(_visibleBreeds[index]);
                  },
                ),
                _buildAnimalDetails(),
                const SizedBox(height: 24),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: FilledButton.styleFrom(
                      backgroundColor: ParakhColors.forestGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(
                      _text('Save animal profile', 'पशु प्रोफाइल सहेजें'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _text('Animal details', 'पशु की जानकारी'),
          style: const TextStyle(
            color: Color(0xFF1B2B21),
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: _text('Approximate weight (kg)', 'अनुमानित वजन (किलो)'),
            prefixIcon: const Icon(Icons.monitor_weight_outlined),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          _text('Life stage', 'जीवन अवस्था'),
          style: const TextStyle(
            color: Color(0xFF26372D),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            _selectionChip(
              value: 'growing',
              selectedValue: _selectedStage,
              label: _text('Growing', 'बढ़ता पशु'),
              onSelected: (value) {
                setState(() {
                  _selectedStage = value;
                });
              },
            ),
            _selectionChip(
              value: 'lactating',
              selectedValue: _selectedStage,
              label: _text('Lactating', 'दूध देने वाला'),
              onSelected: (value) {
                setState(() {
                  _selectedStage = value;
                });
              },
            ),
            _selectionChip(
              value: 'pregnant',
              selectedValue: _selectedStage,
              label: _text('Pregnant', 'गर्भवती'),
              onSelected: (value) {
                setState(() {
                  _selectedStage = value;
                });
              },
            ),
            _selectionChip(
              value: 'dry',
              selectedValue: _selectedStage,
              label: _text('Dry', 'शुष्क अवस्था'),
              onSelected: (value) {
                setState(() {
                  _selectedStage = value;
                });
              },
            ),
          ],
        ),
        if (_selectedStage == 'lactating') ...[
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _milkYieldController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _text('Milk/day (L)', 'दूध/दिन (ली.)'),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _milkFatController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _text('Milk fat (%)', 'दूध वसा (%)'),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Text(
          _text('Production goal', 'उत्पादन लक्ष्य'),
          style: const TextStyle(
            color: Color(0xFF26372D),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            _selectionChip(
              value: 'maintenance',
              selectedValue: _selectedGoal,
              label: _text('Healthy maintenance', 'स्वस्थ रखरखाव'),
              onSelected: (value) {
                setState(() {
                  _selectedGoal = value;
                });
              },
            ),
            _selectionChip(
              value: 'weight_gain',
              selectedValue: _selectedGoal,
              label: _text('Healthy weight gain', 'स्वस्थ वजन बढ़ाना'),
              onSelected: (value) {
                setState(() {
                  _selectedGoal = value;
                });
              },
            ),
            _selectionChip(
              value: 'milk_yield',
              selectedValue: _selectedGoal,
              label: _text('Milk yield', 'दूध उत्पादन'),
              onSelected: (value) {
                setState(() {
                  _selectedGoal = value;
                });
              },
            ),
            _selectionChip(
              value: 'milk_fat',
              selectedValue: _selectedGoal,
              label: _text('Milk fat & SNF', 'दूध वसा और SNF'),
              onSelected: (value) {
                setState(() {
                  _selectedGoal = value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3D7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF92661C),
                size: 21,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _text(
                    'Parakh provides screening guidance. Exact ration changes should be confirmed by a livestock nutrition expert.',
                    'परख प्रारंभिक जाँच मार्गदर्शन देता है। आहार में सटीक बदलाव की पुष्टि पशु पोषण विशेषज्ञ से करें।',
                  ),
                  style: const TextStyle(
                    color: Color(0xFF73551F),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _selectionChip({
    required String value,
    required String selectedValue,
    required String label,
    required ValueChanged<String> onSelected,
  }) {
    final selected = value == selectedValue;

    return ChoiceChip(
      selected: selected,
      label: Text(label),
      showCheckmark: true,
      selectedColor: const Color(0xFFDCECDF),
      side: BorderSide(
        color: selected ? ParakhColors.forestGreen : const Color(0xFFDCE4DA),
      ),
      labelStyle: TextStyle(
        color: selected ? ParakhColors.forestGreen : const Color(0xFF566158),
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
      ),
      onSelected: (_) => onSelected(value),
    );
  }

  Widget _animalCard({
    required String animal,
    required String title,
    required String imagePath,
    required IconData fallbackIcon,
  }) {
    final selected = _selectedAnimal == animal;

    return InkWell(
      onTap: () => _selectAnimal(animal),
      borderRadius: BorderRadius.circular(19),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 150,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE3F0E8) : Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: selected
                ? ParakhColors.forestGreen
                : const Color(0xFFE0E8DD),
            width: selected ? 2.2 : 1,
          ),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Image.asset(
                imagePath,
                width: double.infinity,
                height: 102,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
  debugPrint('Animal image failed: $imagePath');
  debugPrint('Error: $error');
                  return Center(
                    child: Icon(
                      fallbackIcon,
                      size: 55,
                      color: ParakhColors.forestGreen,
                    ),
                  );
                },
              ),
            ),
            if (selected)
              const Positioned(
                right: 9,
                top: 9,
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: ParakhColors.forestGreen,
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 9,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF26372D),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _breedCard(Map<String, String> breed) {
    final id = breed['id']!;
    final imagePath = breed['image']!;
    final selected = _selectedBreed == id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedBreed = id;
        });
      },
      borderRadius: BorderRadius.circular(17),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE3F0E8) : Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected
                ? ParakhColors.forestGreen
                : const Color(0xFFE0E8DD),
            width: selected ? 2.2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: imagePath.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.help_outline_rounded,
                          size: 48,
                          color: Color(0xFF7A847D),
                        ),
                      )
                    : Image.asset(
                        imagePath,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
  debugPrint('Animal image failed: $imagePath');
  debugPrint('Error: $error');
                          return const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 45,
                              color: Color(0xFF94A098),
                            ),
                          );
                        },
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _text(breed['english']!, breed['hindi']!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF26372D),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: ParakhColors.forestGreen,
                      size: 20,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
