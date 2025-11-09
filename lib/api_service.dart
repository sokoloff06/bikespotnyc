import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'parking_spot.dart';
import 'rack_type.dart';

class ApiService {
  static const String _dbName = 'parking_spots.db';
  static const String _tableName = 'spots';
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _dbName);
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        site_id TEXT PRIMARY KEY,
        borough TEXT,
        racktype TEXT,
        latitude REAL,
        longitude REAL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // This is a simple migration strategy suitable for a cache. If the schema
    // changes, we drop the old table and create a new one.
    await db.execute('DROP TABLE IF EXISTS $_tableName');
    await _onCreate(db, newVersion);
  }

  Future<int> _getSpotCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> _initializeAndCacheSpots() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastUpdated = prefs.getString('last_updated_timestamp');
    final int spotCount = await _getSpotCount();

    try {
      final storageRef = FirebaseStorage.instance
          .ref('/files')
          .child('bike_spots.json');
      final metadata = await storageRef.getMetadata();
      final remoteUpdated = metadata.updated;

      // If we have local data and the remote data hasn't changed, we're good.
      if (spotCount > 0 &&
          remoteUpdated != null &&
          lastUpdated == remoteUpdated.toIso8601String()) {
        print("Local cache is up to date.");
        return;
      }

      print("Fetching updated spots from Firebase Storage...");

      // Download to a temporary file to avoid in-memory buffer limitations.
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/bike_spots.json');
      List<ParkingSpot> fetchedSpots = [];

      try {
        await storageRef.writeToFile(tempFile);
        final fileContents = await tempFile.readAsString();
        final jsonList = json.decode(fileContents) as List<dynamic>;
        fetchedSpots = jsonList
            .map((json) => ParkingSpot.fromJson(json))
            .toList();
      } finally {
        if (await tempFile.exists()) await tempFile.delete();
      }

      if (fetchedSpots.isNotEmpty) {
        await insertSpotsIntoDb(fetchedSpots);
        if (remoteUpdated != null) {
          await prefs.setString(
            'last_updated_timestamp',
            remoteUpdated.toIso8601String(),
          );
        }
      }
    } catch (e) {
      print("Error initializing spots from Firebase: $e");
      // If there's an error (e.g., network), we can rely on existing cache if it exists.
      if (spotCount == 0) {
        throw Exception(
          'Failed to initialize parking spots and no cache available.',
        );
      }
    }
  }

  Future<void> insertSpotsIntoDb(List<ParkingSpot> spots) async {
    final db = await database;
    final batch = db.batch();

    batch.delete(_tableName);

    for (final spot in spots) {
      batch.insert(_tableName, {
        'site_id': spot.siteId,
        'borough': spot.borough,
        'racktype': spot.rackType.name,
        'latitude': spot.latitude,
        'longitude': spot.longitude,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // This method is now fully decoupled from any map package.
  Future<List<ParkingSpot>> getSpotsInBounds(
    double south,
    double north,
    double west,
    double east,
  ) async {
    await _initializeAndCacheSpots();

    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where:
          'latitude >= ? AND latitude <= ? AND longitude >= ? AND longitude <= ?',
      whereArgs: [south, north, west, east],
      limit: 500,
    );

    return List.generate(maps.length, (i) {
      return ParkingSpot(
        siteId: maps[i]['site_id'],
        borough: maps[i]['borough'],
        rackType: RackType.fromString(maps[i]['racktype'] ?? ''),
        latitude: maps[i]['latitude'],
        longitude: maps[i]['longitude'],
      );
    });
  }
}
