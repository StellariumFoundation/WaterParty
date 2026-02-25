import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'theme.dart';
import 'providers.dart';
import 'models.dart';
import 'api.dart';
import 'constants.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool isEditing = false;
  bool _isUploading = false;
  int _currentPhotoIndex = 0;
  final PageController _pageController = PageController();

  Future<void> _pickAndUploadPhoto() async {
    final user = ref.read(authProvider).value;
    if (user == null) return;

    int remaining = 12 - user.profilePhotos.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum 12 profile photos allowed")),
      );
      return;
    }

    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 70);

    if (images.isNotEmpty) {
      setState(() => _isUploading = true);
      try {
        // Limit to remaining capacity
        final toUpload = images.length > remaining
            ? images.sublist(0, remaining)
            : images;

        List<String> newHashes = [];
        String? firstThumbHash;
        for (int i = 0; i < toUpload.length; i++) {
          final bytes = await toUpload[i].readAsBytes();
          // Generate thumbnail only for the first photo if user doesn't have one yet
          bool shouldGenThumb =
              (user.thumbnail.isEmpty && i == 0 && user.profilePhotos.isEmpty);
          final uploadResult = await ref
              .read(authProvider.notifier)
              .uploadImage(bytes, "image/jpeg", thumbnail: shouldGenThumb);

          final hash = uploadResult['hash']!;
          newHashes.add(hash);
          if (shouldGenThumb) {
            firstThumbHash = uploadResult['thumbnailHash'];
          }
        }

        final updatedPhotos = [...user.profilePhotos, ...newHashes];
        final updatedUser = user.copyWith(
          profilePhotos: updatedPhotos,
          thumbnail: firstThumbHash ?? user.thumbnail,
        );
        await ref.read(authProvider.notifier).updateUserProfile(updatedUser);

        // Wire to backend
        ref
            .read(socketServiceProvider)
            .sendMessage('UPDATE_PROFILE', updatedUser.toMap());

        if (mounted && images.length > remaining) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Only $remaining photos were added (max 12 reached)",
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  void _deletePhoto(int index) async {
    final user = ref.read(authProvider).value;
    if (user == null) return;

    final updatedPhotos = List<String>.from(user.profilePhotos);
    updatedPhotos.removeAt(index);

    final updatedUser = user.copyWith(profilePhotos: updatedPhotos);
    await ref.read(authProvider.notifier).updateUserProfile(updatedUser);

    ref
        .read(socketServiceProvider)
        .sendMessage('UPDATE_PROFILE', updatedUser.toMap());
    setState(() {});
  }

  // --- Controllers for Text Input ---
  late TextEditingController _realNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _jobCtrl;
  late TextEditingController _companyCtrl;
  late TextEditingController _schoolCtrl;
  late TextEditingController _degreeCtrl;
  late TextEditingController _instaCtrl;
  late TextEditingController _linkedInCtrl;
  late TextEditingController _xCtrl;
  late TextEditingController _tiktokCtrl;

  // --- Local State for Non-Text Fields ---
  int _age = 18;
  int _heightCm = 170;
  String _gender = "OTHER";
  String _drinking = "Social";
  String _smoking = "No";

  // Options for Dropdowns
  final List<String> _habitOptions = ["No", "Social", "Yes"];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    final user = ref.read(authProvider).value;
    if (user == null) return;

    _realNameCtrl = TextEditingController(text: user.realName);
    _phoneCtrl = TextEditingController(text: user.phoneNumber);
    _bioCtrl = TextEditingController(text: user.bio);
    _jobCtrl = TextEditingController(text: user.jobTitle);
    _companyCtrl = TextEditingController(text: user.company);
    _schoolCtrl = TextEditingController(text: user.school);
    _degreeCtrl = TextEditingController(text: user.degree);
    _instaCtrl = TextEditingController(text: user.instagramHandle);
    _linkedInCtrl = TextEditingController(text: user.linkedinHandle);
    _xCtrl = TextEditingController(text: user.xHandle);
    _tiktokCtrl = TextEditingController(text: user.tiktokHandle);

    _age = user.age == 0 ? 18 : user.age;
    _heightCm = user.heightCm == 0 ? 170 : user.heightCm;
    _gender = user.gender.isEmpty ? "OTHER" : user.gender;
    _drinking = user.drinkingPref.isEmpty ? "Social" : user.drinkingPref;
    _smoking = user.smokingPref.isEmpty ? "No" : user.smokingPref;
  }

  @override
  void dispose() {
    _realNameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _jobCtrl.dispose();
    _companyCtrl.dispose();
    _schoolCtrl.dispose();
    _degreeCtrl.dispose();
    _instaCtrl.dispose();
    _linkedInCtrl.dispose();
    _xCtrl.dispose();
    _tiktokCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (isEditing) {
      _saveChanges();
    }
    setState(() => isEditing = !isEditing);
  }

  void _saveChanges() async {
    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(
      realName: _realNameCtrl.text,
      bio: _bioCtrl.text,
      phoneNumber: _phoneCtrl.text,
      jobTitle: _jobCtrl.text,
      company: _companyCtrl.text,
      school: _schoolCtrl.text,
      degree: _degreeCtrl.text,
      instagramHandle: _instaCtrl.text,
      linkedinHandle: _linkedInCtrl.text,
      xHandle: _xCtrl.text,
      tiktokHandle: _tiktokCtrl.text,
      age: _age,
      heightCm: _heightCm,
      gender: _gender,
      drinkingPref: _drinking,
      smokingPref: _smoking,
    );

    // Update locally through the provider
    await ref.read(authProvider.notifier).updateUserProfile(updatedUser);

    // Update ALL fields on the backend via WebSocket
    ref
        .read(socketServiceProvider)
        .sendMessage('UPDATE_PROFILE', updatedUser.toMap());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            if (user.profilePhotos.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                color: Colors.redAccent.withValues(alpha: 0.8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        "PLEASE UPLOAD AT LEAST ONE PHOTO TO ACCESS THE FEED",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isEditing
                        ? _buildPhotoGrid(user)
                        : _buildTinderCarousel(user),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIdentitySection(user),
                          const SizedBox(height: 20),
                          _buildBioSection(),
                          const SizedBox(height: 20),
                          _buildLifestyleSection(),
                          const SizedBox(height: 20),
                          _buildWorkEducationSection(),
                          const SizedBox(height: 20),
                          _buildSocialHandlesSection(),
                          const SizedBox(height: 40),
                          _buildEditButton(),
                          const SizedBox(height: 30),
                          _buildDangerZone(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton() {
    return GestureDetector(
      onTap: _toggleEdit,
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: isEditing
                ? [
                    Colors.greenAccent.withValues(alpha: 0.8),
                    Colors.tealAccent.withValues(alpha: 0.8),
                  ]
                : [AppColors.textCyan, AppColors.electricPurple],
          ),
          boxShadow: [
            BoxShadow(
              color: (isEditing ? Colors.greenAccent : AppColors.textCyan)
                  .withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          isEditing ? "SAVE PROFILE" : "EDIT PROFILE",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildTinderCarousel(User user) {
    final photos = user.profilePhotos;
    if (photos.isEmpty) {
      return SizedBox(
        height: 400,
        child: CachedNetworkImage(
          imageUrl:
              "https://images.unsplash.com/photo-1511367461989-f85a21fda167?q=80&w=1000",
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: Colors.black12),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      );
    }

    return SizedBox(
      height: 500,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: photos.length,
            onPageChanged: (idx) => setState(() => _currentPhotoIndex = idx),
            itemBuilder: (context, index) {
              final photoUrl = photos[index].startsWith("http")
                  ? photos[index]
                  : AppConstants.assetUrl(photos[index]);
              return CachedNetworkImage(
                imageUrl: photoUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.black12),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              );
            },
          ),

          // Tinder-style Progress Indicators
          Positioned(
            top: 15,
            left: 10,
            right: 10,
            child: Row(
              children: List.generate(photos.length, (index) {
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _currentPhotoIndex == index
                          ? Colors.white
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Tap Areas for Navigation
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_currentPhotoIndex > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_currentPhotoIndex < photos.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Gradient Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Trust Badge
          Positioned(
            bottom: 20,
            right: 20,
            child: WaterGlass(
              width: 100,
              height: 35,
              borderRadius: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield, color: AppColors.gold, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    "${user.trustScore} TRUST",
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(User user) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PROFILE PHOTOS",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPink,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                "${user.profilePhotos.length}/12",
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              if (index < user.profilePhotos.length) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: CachedNetworkImage(
                        imageUrl: AppConstants.assetUrl(
                          user.profilePhotos[index],
                        ),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) =>
                            Container(color: Colors.black12),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: () => _deletePhoto(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                bool isNext = index == user.profilePhotos.length;
                return GestureDetector(
                  onTap: isNext
                      ? (_isUploading ? null : _pickAndUploadPhoto)
                      : null,
                  child: WaterGlass(
                    borderRadius: 15,
                    child: (isNext && _isUploading)
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.textCyan,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            Icons.add_a_photo,
                            color: isNext
                                ? Colors.white24
                                : Colors.white.withValues(alpha: 0.02),
                          ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: isEditing
                  ? TextField(
                      controller: _realNameCtrl,
                      style: Theme.of(
                        context,
                      ).textTheme.displayMedium?.copyWith(fontSize: 32),
                      decoration: const InputDecoration(
                        hintText: "Your Name",
                        border: InputBorder.none,
                      ),
                    )
                  : Text(
                      user.realName,
                      style: Theme.of(
                        context,
                      ).textTheme.displayMedium?.copyWith(fontSize: 32),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    if (!isEditing && _bioCtrl.text.trim().isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ABOUT ME",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white38,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 5),
        isEditing
            ? WaterGlass(
                height: 100,
                child: TextField(
                  controller: _bioCtrl,
                  maxLines: 4,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(15),
                  ),
                ),
              )
            : Text(
                _bioCtrl.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: Colors.white70,
                ),
              ),
      ],
    );
  }

  Widget _buildLifestyleSection() {
    // Lifestyle fields often have defaults, but let's check if they are "unset" or default
    // _heightCm (default 170), _drinking (default "Social"), _smoking (default "No")
    // If the user hasn't touched them, they might still be at defaults.
    // However, the request is to hide if "no data".
    // Usually, this refers to optional fields. Lifestyle fields here seem to have defaults.
    // Let's assume height 0 or empty gender/prefs means no data.

    bool hasData =
        _heightCm > 0 ||
        _gender != "OTHER" ||
        _drinking != "Social" ||
        _smoking != "No";
    // Actually, "Social" and "No" are data points.
    // Maybe the user wants to hide the section if it's just defaults?
    // Let's stick to hiding if NOT editing and everything is at default.

    if (!isEditing && !hasData) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("LIFESTYLE"),
        if (isEditing) ...[
          Text(
            "GENDER",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _genderEditChip("MALE"),
              const SizedBox(width: 10),
              _genderEditChip("FEMALE"),
              const SizedBox(width: 10),
              _genderEditChip("OTHER"),
            ],
          ),
          const SizedBox(height: 20),
        ],
        Row(
          children: [
            Expanded(
              child: isEditing
                  ? _buildHeightEditTile()
                  : _buildInfoTile(Icons.straighten, "Height", "$_heightCm cm"),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDropdownTile(
                Icons.local_bar,
                "Drinks",
                _drinking,
                (v) => setState(() => _drinking = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildDropdownTile(
                Icons.smoking_rooms,
                "Smoke",
                _smoking,
                (v) => setState(() => _smoking = v),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _genderEditChip(String label) {
    bool active = _gender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = label),
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.textCyan : Colors.white10,
            ),
            color: active
                ? AppColors.textCyan.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: active ? Colors.white : Colors.white24,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeightEditTile() {
    return WaterGlass(
      height: 60,
      borderRadius: 15,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            const Icon(Icons.straighten, color: Colors.white38, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  hintText: "Height",
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (v) => _heightCm = int.tryParse(v) ?? _heightCm,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownTile(
    IconData icon,
    String label,
    String value,
    Function(String) onChanged,
  ) {
    if (!isEditing) {
      return _buildInfoTile(icon, label, value);
    }
    return WaterGlass(
      height: 60,
      borderRadius: 15,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white38),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _habitOptions.contains(value)
                      ? value
                      : _habitOptions.first,
                  dropdownColor: Colors.grey[900],
                  isDense: true,
                  items: _habitOptions
                      .map(
                        (opt) => DropdownMenuItem(
                          value: opt,
                          child: Text(
                            opt,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onChanged(v);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return WaterGlass(
      height: 60,
      borderRadius: 15,
      child: Row(
        children: [
          const SizedBox(width: 15),
          Icon(icon, color: Colors.white38, size: 18),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white38,
                  fontSize: 9,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkEducationSection() {
    bool hasData =
        _jobCtrl.text.trim().isNotEmpty ||
        _companyCtrl.text.trim().isNotEmpty ||
        _schoolCtrl.text.trim().isNotEmpty ||
        _degreeCtrl.text.trim().isNotEmpty ||
        _phoneCtrl.text.trim().isNotEmpty;

    if (!isEditing && !hasData) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("WORK & EDUCATION"),
        _buildListInput(_jobCtrl, Icons.work_outline, "Job Title", "Add Job"),
        const SizedBox(height: 10),
        _buildListInput(
          _companyCtrl,
          Icons.business_outlined,
          "Company",
          "Add Company",
        ),
        const SizedBox(height: 10),
        _buildListInput(
          _schoolCtrl,
          Icons.school_outlined,
          "School",
          "Add School",
        ),
        const SizedBox(height: 10),
        _buildListInput(
          _degreeCtrl,
          Icons.description_outlined,
          "Degree",
          "Add Degree",
        ),
        const SizedBox(height: 10),
        _buildListInput(
          _phoneCtrl,
          Icons.phone_outlined,
          "Phone Number",
          "Add Phone",
        ),
      ],
    );
  }

  Widget _buildSocialHandlesSection() {
    bool hasData =
        _instaCtrl.text.trim().isNotEmpty ||
        _xCtrl.text.trim().isNotEmpty ||
        _tiktokCtrl.text.trim().isNotEmpty ||
        _linkedInCtrl.text.trim().isNotEmpty;

    if (!isEditing && !hasData) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("SOCIAL ECOSYSTEM"),
        _buildListInput(
          _instaCtrl,
          FontAwesomeIcons.instagram,
          "Instagram",
          "Add Instagram",
        ),
        const SizedBox(height: 10),
        _buildListInput(
          _xCtrl,
          FontAwesomeIcons.xTwitter,
          "X (Twitter)",
          "Add X",
        ),
        const SizedBox(height: 10),
        _buildListInput(
          _tiktokCtrl,
          FontAwesomeIcons.tiktok,
          "TikTok",
          "Add TikTok",
        ),
        const SizedBox(height: 10),
        _buildListInput(
          _linkedInCtrl,
          FontAwesomeIcons.linkedin,
          "LinkedIn",
          "Add LinkedIn",
        ),
      ],
    );
  }

  Widget _buildListInput(
    TextEditingController ctrl,
    IconData icon,
    String hint,
    String emptyLabel,
  ) {
    if (!isEditing && ctrl.text.isEmpty) return const SizedBox();

    String cleanText = ctrl.text.trim();
    bool isSocial =
        (icon == FontAwesomeIcons.instagram ||
        icon == FontAwesomeIcons.xTwitter ||
        icon == FontAwesomeIcons.tiktok ||
        icon == FontAwesomeIcons.linkedin);

    bool isLinkable = !isEditing && cleanText.isNotEmpty && isSocial;

    return GestureDetector(
      onTap: isLinkable
          ? () async {
              String input = cleanText;
              String url = input;

              if (!input.startsWith('http')) {
                // It's likely a handle
                String handle = input.startsWith('@')
                    ? input.substring(1)
                    : input;

                if (icon == FontAwesomeIcons.instagram) {
                  url = 'https://instagram.com/$handle';
                } else if (icon == FontAwesomeIcons.xTwitter) {
                  url = 'https://twitter.com/$handle';
                } else if (icon == FontAwesomeIcons.tiktok) {
                  url = 'https://tiktok.com/@$handle';
                } else if (icon == FontAwesomeIcons.linkedin) {
                  if (!handle.contains('/')) {
                    url = 'https://linkedin.com/in/$handle';
                  } else {
                    url = 'https://linkedin.com/$handle';
                  }
                }
              }

              final uri = Uri.tryParse(url);
              if (uri != null) {
                try {
                  // Try with external application mode first (opens in browser/app)
                  final launched = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );

                  if (!launched) {
                    // Fallback: try platform default
                    await launchUrl(uri);
                  }
                } catch (e) {
                  // If all else fails, try with platform default
                  try {
                    await launchUrl(uri);
                  } catch (_) {
                    // Silently fail - don't show error to user
                  }
                }
              }
            }
          : null,
      child: WaterGlass(
        height: 55,
        borderRadius: 15,
        child: TextField(
          controller: ctrl,
          enabled: isEditing,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isLinkable ? AppColors.textCyan : Colors.white,
            decoration: isLinkable ? TextDecoration.underline : null,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: isLinkable
                  ? AppColors.textCyan
                  : AppColors.textCyan.withValues(alpha: 0.4),
              size: 18,
            ),
            hintText: hint,
            hintStyle: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white24),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    if (!isEditing) return const SizedBox();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _showLogoutConfirmation,
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "LOGOUT",
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: GestureDetector(
                onTap: _showDeleteConfirmation,
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "DELETE ACCOUNT",
                    style: TextStyle(
                      color: Colors.redAccent.withValues(alpha: 0.6),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to logout?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text(
              "LOGOUT",
              style: TextStyle(color: AppColors.textCyan),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    print('[Profile] _showDeleteConfirmation called');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Delete Account",
          style: TextStyle(color: Colors.redAccent),
        ),
        content: const Text(
          "This action is permanent and cannot be undone. All your data will be wiped.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              print('[Profile] Delete account confirmed by user');
              try {
                await ref.read(authProvider.notifier).deleteAccount();
                print(
                  '[Profile] deleteAccount completed successfully - app will navigate to login',
                );
              } catch (e) {
                print('[Profile] deleteAccount failed: $e');
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
              }
            },
            child: const Text(
              "DELETE",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textPink,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
