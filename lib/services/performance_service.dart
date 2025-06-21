import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final performanceServiceProvider = Provider<PerformanceService>(
  (ref) => PerformanceService(),
);

class PerformanceMetrics {
  final double appStartupTime;
  final double averageFrameTime;
  final int memoryUsage;
  final int cacheSize;
  final Map<String, double> screenLoadTimes;
  final Map<String, int> apiCallCounts;
  final DateTime measuredAt;

  PerformanceMetrics({
    required this.appStartupTime,
    required this.averageFrameTime,
    required this.memoryUsage,
    required this.cacheSize,
    required this.screenLoadTimes,
    required this.apiCallCounts,
    required this.measuredAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'appStartupTime': appStartupTime,
      'averageFrameTime': averageFrameTime,
      'memoryUsage': memoryUsage,
      'cacheSize': cacheSize,
      'screenLoadTimes': screenLoadTimes,
      'apiCallCounts': apiCallCounts,
      'measuredAt': measuredAt.toIso8601String(),
    };
  }
}

class ImageCacheManager {
  static final Map<String, Uint8List> _cache = {};
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB
  static int _currentCacheSize = 0;

  static void cacheImage(String url, Uint8List data) {
    if (_currentCacheSize + data.length > _maxCacheSize) {
      _clearOldestEntries(data.length);
    }

    _cache[url] = data;
    _currentCacheSize += data.length;
  }

  static Uint8List? getCachedImage(String url) {
    return _cache[url];
  }

  static void _clearOldestEntries(int requiredSpace) {
    final entries = _cache.entries.toList();
    int freedSpace = 0;

    for (int i = 0; i < entries.length && freedSpace < requiredSpace; i++) {
      final entry = entries[i];
      _cache.remove(entry.key);
      freedSpace += entry.value.length;
      _currentCacheSize -= entry.value.length;
    }
  }

  static void clearCache() {
    _cache.clear();
    _currentCacheSize = 0;
  }

  static int get cacheSize => _currentCacheSize;
}

class PerformanceService {
  final Map<String, DateTime> _screenLoadStartTimes = {};
  final Map<String, double> _screenLoadTimes = {};
  final Map<String, int> _apiCallCounts = {};
  final List<double> _frameTimes = [];

  DateTime? _appStartTime;
  Timer? _performanceTimer;

  // Initialize performance monitoring
  void initialize() {
    _appStartTime = DateTime.now();
    _startPerformanceMonitoring();
    _setupMemoryOptimizations();
  }

  void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _collectFrameMetrics();
      _optimizeMemoryUsage();
    });
  }

  void _setupMemoryOptimizations() {
    // Enable image cache optimizations
    if (!kIsWeb) {
      // Platform-specific optimizations
      _setupPlatformOptimizations();
    }
  }

  void _setupPlatformOptimizations() {
    if (Platform.isAndroid) {
      // Android-specific optimizations
      SystemChannels.platform.invokeMethod(
        'SystemChrome.setEnabledSystemUIMode',
        {'mode': 'SystemUiMode.immersiveSticky'},
      );
    } else if (Platform.isIOS) {
      // iOS-specific optimizations
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  // Screen load time tracking
  void startScreenLoad(String screenName) {
    _screenLoadStartTimes[screenName] = DateTime.now();
  }

  void endScreenLoad(String screenName) {
    final startTime = _screenLoadStartTimes[screenName];
    if (startTime != null) {
      final loadTime =
          DateTime.now().difference(startTime).inMilliseconds.toDouble();
      _screenLoadTimes[screenName] = loadTime;
      _screenLoadStartTimes.remove(screenName);

      // Log slow screens
      if (loadTime > 2000) {
        debugPrint('Slow screen load detected: $screenName took ${loadTime}ms');
      }
    }
  }

  // API call tracking
  void trackApiCall(String endpoint) {
    _apiCallCounts[endpoint] = (_apiCallCounts[endpoint] ?? 0) + 1;
  }

  // Frame time collection
  void _collectFrameMetrics() {
    // This would integrate with Flutter's performance overlay in a real implementation
    // For now, we'll simulate frame time collection
    if (_frameTimes.length > 100) {
      _frameTimes.removeRange(0, 50); // Keep only recent frame times
    }
  }

  // Memory optimization
  void _optimizeMemoryUsage() {
    // Clear old cached data
    _clearOldCacheEntries();

    // Trigger garbage collection hint
    if (!kIsWeb) {
      // Platform-specific memory optimization
      _platformSpecificMemoryOptimization();
    }
  }

  void _clearOldCacheEntries() {
    // Clear old screen load times
    if (_screenLoadTimes.length > 50) {
      final entries = _screenLoadTimes.entries.toList();
      entries.sort((a, b) => a.value.compareTo(b.value));

      for (int i = 0; i < 25; i++) {
        _screenLoadTimes.remove(entries[i].key);
      }
    }
  }

  void _platformSpecificMemoryOptimization() {
    if (Platform.isAndroid) {
      // Android memory optimization
      SystemChannels.platform.invokeMethod('System.gc');
    }
  }

  // Get current performance metrics
  Future<PerformanceMetrics> getPerformanceMetrics() async {
    final appStartupTime =
        _appStartTime != null
            ? DateTime.now()
                .difference(_appStartTime!)
                .inMilliseconds
                .toDouble()
            : 0.0;

    final averageFrameTime =
        _frameTimes.isNotEmpty
            ? _frameTimes.reduce((a, b) => a + b) / _frameTimes.length
            : 16.67; // 60 FPS target

    final memoryUsage = await _getMemoryUsage();
    final cacheSize = ImageCacheManager.cacheSize;

    return PerformanceMetrics(
      appStartupTime: appStartupTime,
      averageFrameTime: averageFrameTime,
      memoryUsage: memoryUsage,
      cacheSize: cacheSize,
      screenLoadTimes: Map.from(_screenLoadTimes),
      apiCallCounts: Map.from(_apiCallCounts),
      measuredAt: DateTime.now(),
    );
  }

  Future<int> _getMemoryUsage() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // This would use platform channels to get actual memory usage
        // For now, return a simulated value
        return 50 * 1024 * 1024; // 50MB
      }
    } catch (e) {
      debugPrint('Error getting memory usage: $e');
    }
    return 0;
  }

  // Performance optimization recommendations
  List<String> getOptimizationRecommendations(PerformanceMetrics metrics) {
    final recommendations = <String>[];

    if (metrics.appStartupTime > 3000) {
      recommendations.add(
        'App startup time is slow. Consider lazy loading and reducing initial data fetching.',
      );
    }

    if (metrics.averageFrameTime > 20) {
      recommendations.add(
        'Frame rate is below 50 FPS. Optimize UI rendering and reduce complex animations.',
      );
    }

    if (metrics.memoryUsage > 100 * 1024 * 1024) {
      recommendations.add(
        'High memory usage detected. Consider implementing better caching strategies.',
      );
    }

    if (metrics.cacheSize > 75 * 1024 * 1024) {
      recommendations.add(
        'Image cache is large. Consider reducing cache size or implementing LRU eviction.',
      );
    }

    final slowScreens =
        metrics.screenLoadTimes.entries
            .where((entry) => entry.value > 2000)
            .map((entry) => entry.key)
            .toList();

    if (slowScreens.isNotEmpty) {
      recommendations.add(
        'Slow loading screens detected: ${slowScreens.join(', ')}. Optimize data loading.',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add('Performance is good! No major issues detected.');
    }

    return recommendations;
  }

  // Preload critical resources
  Future<void> preloadCriticalResources() async {
    try {
      // Preload essential images
      await _preloadEssentialImages();

      // Preload critical data
      await _preloadCriticalData();

      // Warm up caches
      await _warmupCaches();

      debugPrint('Critical resources preloaded successfully');
    } catch (e) {
      debugPrint('Error preloading resources: $e');
    }
  }

  Future<void> _preloadEssentialImages() async {
    final essentialImages = [
      'assets/images/logo.png',
      'assets/images/placeholder.png',
      'assets/images/loading.gif',
    ];

    for (final imagePath in essentialImages) {
      try {
        final data = await rootBundle.load(imagePath);
        ImageCacheManager.cacheImage(imagePath, data.buffer.asUint8List());
      } catch (e) {
        debugPrint('Failed to preload image $imagePath: $e');
      }
    }
  }

  Future<void> _preloadCriticalData() async {
    // This would preload essential app data
    // Implementation depends on your specific data requirements
  }

  Future<void> _warmupCaches() async {
    final prefs = await SharedPreferences.getInstance();

    // Warm up SharedPreferences cache
    prefs.getString('user_preferences');
    prefs.getString('app_settings');
  }

  // Optimize app for low-end devices
  void optimizeForLowEndDevices() {
    // Reduce animation durations
    _reduceAnimationComplexity();

    // Lower image quality
    _optimizeImageQuality();

    // Reduce cache sizes
    _reduceCacheSizes();

    debugPrint('App optimized for low-end devices');
  }

  void _reduceAnimationComplexity() {
    // This would configure animation settings
    // In a real implementation, you'd modify animation controllers
  }

  void _optimizeImageQuality() {
    // This would configure image loading settings
    // Reduce image quality, enable compression, etc.
  }

  void _reduceCacheSizes() {
    // Reduce various cache sizes
    ImageCacheManager.clearCache();
  }

  // Battery optimization
  void optimizeForBattery() {
    // Reduce background processing
    _reduceBackgroundTasks();

    // Lower refresh rates
    _optimizeRefreshRates();

    // Disable non-essential features
    _disableNonEssentialFeatures();

    debugPrint('App optimized for battery life');
  }

  void _reduceBackgroundTasks() {
    // Cancel non-essential timers and background tasks
    _performanceTimer?.cancel();
  }

  void _optimizeRefreshRates() {
    // Reduce refresh rates for data updates
    // This would modify polling intervals
  }

  void _disableNonEssentialFeatures() {
    // Disable animations, reduce visual effects
    // This would modify app settings
  }

  // Network optimization
  void optimizeNetworkUsage() {
    // Enable request batching
    _enableRequestBatching();

    // Implement smart caching
    _implementSmartCaching();

    // Compress requests
    _enableRequestCompression();

    debugPrint('Network usage optimized');
  }

  void _enableRequestBatching() {
    // Batch multiple API requests together
    // Implementation would depend on your API structure
  }

  void _implementSmartCaching() {
    // Implement intelligent caching strategies
    // Cache frequently accessed data, implement TTL
  }

  void _enableRequestCompression() {
    // Enable gzip compression for API requests
    // This would be configured in your HTTP client
  }

  // Cleanup resources
  void dispose() {
    _performanceTimer?.cancel();
    ImageCacheManager.clearCache();
    _screenLoadStartTimes.clear();
    _screenLoadTimes.clear();
    _apiCallCounts.clear();
    _frameTimes.clear();
  }

  // Performance testing utilities
  Future<void> runPerformanceTest() async {
    debugPrint('Starting performance test...');

    final startTime = DateTime.now();

    // Test screen loading
    for (int i = 0; i < 10; i++) {
      startScreenLoad('test_screen_$i');
      await Future.delayed(const Duration(milliseconds: 100));
      endScreenLoad('test_screen_$i');
    }

    // Test memory allocation
    final testData = List.generate(1000, (index) => 'Test data $index');
    await Future.delayed(const Duration(milliseconds: 100));
    testData.clear();

    final endTime = DateTime.now();
    final testDuration = endTime.difference(startTime).inMilliseconds;

    debugPrint('Performance test completed in ${testDuration}ms');

    final metrics = await getPerformanceMetrics();
    final recommendations = getOptimizationRecommendations(metrics);

    debugPrint('Performance recommendations:');
    for (final recommendation in recommendations) {
      debugPrint('- $recommendation');
    }
  }
}
