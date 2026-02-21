import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'theme.dart';
import 'providers.dart';
import 'models.dart';
import 'websocket.dart';
import 'constants.dart';

class PartyFeedScreen extends ConsumerStatefulWidget {
  const PartyFeedScreen({super.key});

  @override
  ConsumerState<PartyFeedScreen> createState() => _PartyFeedScreenState();
}

class _PartyFeedScreenState extends ConsumerState<PartyFeedScreen> {
  final CardSwiperController controller = CardSwiperController();
  bool _isInitialLoading = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndFetchLocation();
    });
  }

  Future<void> _checkAndFetchLocation() async {
    final existingLoc = ref.read(locationProvider).value;
    
    if (existingLoc != null) {
      // We have a location! Start loading feed immediately
      _fetchFeed(existingLoc.lat, existingLoc.lon);
      if (mounted) setState(() => _isInitialLoading = false);
      
      // Still refresh location silently in background, but only if it's "old" (e.g. > 5 mins)
      if (DateTime.now().difference(existingLoc.timestamp).inMinutes > 5) {
        _determinePosition(silent: true);
      }
    } else {
      // No location yet, must fetch
      _determinePosition();
    }
  }

  Future<void> _fetchFeed(double lat, double lon) async {
    ref.read(socketServiceProvider).sendMessage('GET_FEED', {
      'Lat': lat,
      'Lon': lon,
      'RadiusKm': 50.0,
    });
  }

  Future<void> _determinePosition({bool silent = false}) async {
    bool serviceEnabled;
    LocationPermission permission;

    if (!silent) {
      setState(() { _isInitialLoading = true; _locationError = null; });
    }

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (silent) return;
        throw 'Location services are disabled.';
      }

      permission = await Geolocator.checkPermission();
      
      // If we already have permission, don't ask again
      if (permission == LocationPermission.denied) {
        if (silent) return; 
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Location permissions are denied';
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (silent) return;
        throw 'Location permissions are permanently denied.';
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      
      await ref.read(locationProvider.notifier).updateLocation(position.latitude, position.longitude);
      _fetchFeed(position.latitude, position.longitude);

      if (mounted) setState(() => _isInitialLoading = false);
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _locationError = e.toString();
          _isInitialLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final parties = ref.watch(partyFeedProvider);
    final locationAsync = ref.watch(locationProvider);
    final currentLoc = locationAsync.value;

    // Only show loading if we have absolutely no location and we are currently fetching
    if (_isInitialLoading && currentLoc == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.textCyan));
    }

    if (_locationError != null && currentLoc == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, color: Colors.white24, size: 50),
            const SizedBox(height: 20),
            Text(_locationError!, style: const TextStyle(color: Colors.white54, )),
            TextButton(onPressed: _determinePosition, child: const Text("RETRY", style: TextStyle(color: AppColors.textCyan))),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true, 
      body: Stack(
        children: [
          Positioned.fill(
            child: parties.isEmpty
                ? _buildEmptyState()
                : CardSwiper(
                    controller: controller,
                    cardsCount: parties.length,
                    numberOfCardsDisplayed: 1,
                    isDisabled: false,
                    padding: EdgeInsets.zero,
                    onSwipe: (previousIndex, currentIndex, direction) {
                      final party = parties[previousIndex];
                      // 1. Remove from local buffer immediately
                      ref.read(partyFeedProvider.notifier).markAsSwiped(party.id);
                      
                      // 2. Send Swipe to Backend
                      ref.read(socketServiceProvider).sendMessage('SWIPE', {
                        'PartyID': party.id,
                        'Direction': direction.name,
                      });
                      return true;
                    },
                    cardBuilder: (context, index, x, y) {
                      return _buildFeedCard(context, parties[index]);
                    },
                  ),
          ),

          // Layer 2: Action Buttons
          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _roundActionButton(FontAwesomeIcons.xmark, AppColors.textPink, () {
                  controller.swipe(CardSwiperDirection.left);
                }),
                _roundActionButton(FontAwesomeIcons.check, AppColors.textCyan, () {
                  controller.swipe(CardSwiperDirection.right);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedCard(BuildContext context, Party party) {
    final displayImage = party.partyPhotos.isNotEmpty 
        ? AppConstants.assetUrl(party.partyPhotos.first) 
        : "https://images.unsplash.com/photo-1492684223066-81342ee5ff30?q=80&w=1000"; // Neutral Party Placeholder

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => PartyDetailScreen(party: party)),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(displayImage, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.1), Colors.transparent, Colors.black.withOpacity(0.9)],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            bottom: 210,
            left: 25,
            right: 25,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  party.title.toUpperCase(),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                        letterSpacing: -1,
                      ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _chip(context, party.city.toUpperCase(), AppColors.textCyan),
                    const SizedBox(width: 10),
                    _chip(context, "${party.maxCapacity - party.currentGuestCount} SLOTS", AppColors.gold),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  party.vibeTags.take(3).join(" • ").toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              )),
    );
  }

  Widget _roundActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: WaterGlass(
        width: 75, height: 75,
        borderRadius: 40,
        borderColor: color.withOpacity(0.4),
        border: 2,
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(FontAwesomeIcons.water, color: AppColors.textCyan, size: 40),
          const SizedBox(height: 25),
          Text("SILENCE",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w900,
                  )),
          Text("NO VIBES NEARBY",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  )),
        ],
      ),
    );
  }
}

// ==========================================
// THE DETAILED "WHOLE CARD" VIEW
// ==========================================

class PartyDetailScreen extends StatelessWidget {
  final Party party;
  const PartyDetailScreen({required this.party, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 500,
                pinned: true,
                backgroundColor: Colors.black,
                leading: const SizedBox(),
                flexibleSpace: FlexibleSpaceBar(
                  background:
                      Image.network(party.partyPhotos.first, fit: BoxFit.cover),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(party.title,
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              )),
                      const SizedBox(height: 25),
                      Row(
                        children: [
                          _detailStat(context, FontAwesomeIcons.clock, "STARTS",
                              "${party.startTime.hour}:00"),
                          const Spacer(),
                          _detailStat(
                              context, FontAwesomeIcons.locationDot, "CITY", party.city),
                          const Spacer(),
                          _detailStat(context, FontAwesomeIcons.userGroup, "LIMIT",
                              "${party.maxCapacity}"),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Text("PROTOCOL",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textPink,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              )),
                      const SizedBox(height: 15),
                      Text(party.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.6,
                                color: Colors.white70,
                              )),
                      if (party.rotationPool != null) ...[
                        const SizedBox(height: 40),
                        Text("ROTATION POOL",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                )),
                        const SizedBox(height: 15),
                        WaterGlass(
                          height: 80,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(FontAwesomeIcons.wallet,
                                  color: AppColors.gold, size: 18),
                              const SizedBox(width: 15),
                              Text(
                                "\$${party.rotationPool!.currentAmount.toInt()} / \$${party.rotationPool!.targetAmount.toInt()}",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                              )
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 200),
                    ],
                  ),
                ),
              )
            ],
          ),

          Positioned(
            top: 60,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: WaterGlass(
                  width: 50,
                  height: 50,
                  borderRadius: 25,
                  child: const Icon(FontAwesomeIcons.xmark,
                      color: Colors.white, size: 20)),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _decisionBtn(context, FontAwesomeIcons.xmark, AppColors.textPink,
                    "SKIP", () => Navigator.pop(context)),
                _decisionBtn(context, FontAwesomeIcons.bolt, AppColors.textCyan,
                    "REQUEST", () => Navigator.pop(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailStat(
      BuildContext context, IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 10, color: Colors.white38),
          const SizedBox(width: 5),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white38, fontWeight: FontWeight.bold))
        ]),
        const SizedBox(height: 5),
        Text(value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                )),
      ],
    );
  }

  Widget _decisionBtn(BuildContext context, IconData icon, Color color,
      String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          WaterGlass(
              width: 80,
              height: 80,
              borderRadius: 40,
              borderColor: color,
              border: 2,
              child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 10),
          Text(label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  )),
        ],
      ),
    );
  }
}
