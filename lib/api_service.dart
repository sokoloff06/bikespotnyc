import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'parking_spot.dart';

class ApiService {
  final String _baseUrl =
      'https://data.cityofnewyork.us/resource/592z-n7dk.json';
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
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        site_id TEXT PRIMARY KEY,
        borough TEXT,
        latitude REAL,
        longitude REAL
      )
    ''');
  }

  Future<int> _getSpotCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> _initializeAndCacheSpots() async {
    final prefs = await SharedPreferences.getInstance();
    final int lastFetched = prefs.getInt('last_fetched_timestamp') ?? 0;
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int spotCount = await _getSpotCount();

    if (spotCount > 0 && (now - lastFetched <= 24 * 60 * 60 * 1000)) {
      return;
    }

    List<ParkingSpot> fetchedSpots = [];
    int offset = 0;
    const int limit = 1000;
    bool hasMoreData = true;

    while (hasMoreData) {
      final response = await http
          .get(Uri.parse('$_baseUrl?\$limit=$limit&\$offset=$offset'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        if (jsonList.isEmpty || jsonList.length < limit) {
          hasMoreData = false;
        }
        fetchedSpots.addAll(
            jsonList.map((json) => ParkingSpot.fromJson(json)).toList());
        offset += limit;
      } else {
        throw Exception('Failed to load parking spots');
      }
    }
    // Do not overwrite local DB if there are no spots.
    if (fetchedSpots.isEmpty) return;
    await _insertSpotsIntoDb(fetchedSpots);
    await prefs.setInt('last_fetched_timestamp', now);
  }

  Future<void> _insertSpotsIntoDb(List<ParkingSpot> spots) async {
    final db = await database;
    final batch = db.batch();

    batch.delete(_tableName);

    for (final spot in spots) {
      batch.insert(
        _tableName,
        {
          'site_id': spot.siteId,
          'borough': spot.borough,
          'latitude': spot.latitude,
          'longitude': spot.longitude,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
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
        latitude: maps[i]['latitude'],
        longitude: maps[i]['longitude'],
      );
    });
  }
}