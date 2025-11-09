
## Project Blueprint: NYC Bicycle Parking Finder

## Overview

This document outlines the plan for creating a Flutter application that displays bicycle parking locations in New York City on an interactive map. The application will fetch data from a `spots.json` file hosted in a Firebase Cloud Storage bucket, implement local caching in an SQLite database to reduce network requests, and display the parking spots as markers on a map.

## Features

*   **Interactive Map:** Users will see a map of NYC with markers indicating bicycle parking locations.
*   **Marker Clustering:** To improve performance and readability, markers will be clustered together at higher zoom levels.
*   **Data Caching:** The application will cache the parking data in a local SQLite database to provide a fast, offline-first experience. Data is synchronized from Firebase Storage when the app starts if updates are available.
*   **Detailed Information:** Tapping on a parking marker will display more information about that location.
*   **Current Location:** The map will show the user's current location and allow them to center the map on it.
*   **Data Model:** The `ParkingSpot` data model includes `siteId`, `borough`, `rackType`, `latitude`, and `longitude`.

## Architecture

*   **State Management:** Provider for managing the state of the parking data.
*   **Data Fetching:** The `firebase_storage` package is used to download parking data from the cloud.
*   **Mapping:** The `flutter_map` package is used to display the interactive map. `flutter_map_marker_cluster` is used for clustering.
*   **Local Caching:** The `sqflite` package is used for the local database cache. `shared_preferences` stores the timestamp of the last data sync.
*   **Location:** The `geolocator` package is used to get the user's current location.

## Current Plan: Integrate Firebase Storage

1.  **Add Firebase Dependencies:** Add `firebase_core` and `firebase_storage` to `pubspec.yaml`.
2.  **Initialize Firebase:** Create a `lib/main.dart` file and ensure `Firebase.initializeApp()` is called before the app runs.
3.  **Update ApiService:** Modify `ApiService` to fetch a `spots.json` file from Firebase Storage instead of the NYC OpenData HTTP endpoint.
4.  **Implement Cache Checking:** Use the file metadata from Firebase Storage to check if the local SQLite cache is stale. If it is, download the new file and update the local database.
5.  **Update Blueprint:** Reflect the architectural change from using an HTTP API to Firebase Storage in `blueprint.md`.
