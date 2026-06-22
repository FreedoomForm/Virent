# Lime-RNMapbox Analysis + Open-Source Map Solution

## What Lime-RNMapbox does well (to adopt):

### 1. Provider Pattern (Context API → Riverpod)
- AuthProvider: session management, auto-refresh, isAuthenticated
- ScooterProvider: nearby scooters, selected scooter, directions, isNearby
- RideProvider: active ride, real-time route tracking via location subscription
- Nested providers: Auth → Scooter → Ride (dependency chain)

### 2. Real-time Route Tracking (KILLER FEATURE)
- During ride: Location.watchPositionAsync({distanceInterval: 30})
- Each GPS update appends to rideRoute array
- Route drawn as polyline on map in real-time
- This is the "breadcrumb trail" showing where you've been

### 3. Scooter Clustering on Map
- ShapeSource with cluster={true}
- Cluster count shown as text on green circle
- Individual scooters shown as pin icons
- Clusters expand when zoomed in

### 4. Direction API Integration
- getDirections(from, to) → returns route geometry + duration + distance
- fetchDirectionBasedOnCoords(coordinates) → map matching for recorded route
- Route shown as green LineLayer on map

### 5. Bottom Sheet Pattern
- SelectedScooterSheet: shows when scooter tapped, expands to 200dp
- ActiveRideSheet: shows during ride, "Finish journey" button
- BottomSheet from @gorhom/bottom-sheet (in Flutter: DraggableScrollableSheet)

### 6. Proximity Detection
- watchPositionAsync with distanceInterval: 10m
- Calculate distance from user to scooter using @turf/distance
- If distance < 100m → setIsNearby(true) → enable "Start journey" button
- User can only start ride when within 100m of scooter

### 7. Supabase Integration (→ our embedded server)
- nearby_scooters RPC (PostGIS function) — we do this in Dart
- rides table with finished_at null check for active ride
- Real-time subscription for scooter updates

## Open-Source Google Maps Alternative

### For Flutter: flutter_map (already using!) + OSRM

**Map tiles (free, no API key):**
- OpenStreetMap tiles: https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
- CartoDB: https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png (dark theme)
- Stamen: https://stamen-tiles.a.ssl.fastly.net/toner/{z}/{x}/{y}.png (black/white)
- Esri satellite: https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}

**Directions/Routing (free, self-hosted OSRM):**
- OSRM demo server: https://router.project-osrm.org/route/v1/foot/{lng1},{lat1};{lng2},{lat2}
- Returns: route geometry (polyline), duration, distance, steps
- Self-host with Docker: docker run -p 5000:5000 osrm/osrm-backend osrm-routed --algorithm mld /data.osm.pbf
- No API key, no rate limit, no cost

**Geocoding/Search (free, self-hosted Nominatim):**
- Nominatim demo: https://nominatim.openstreetmap.org/search?q=Tashkent&format=json
- Returns: lat, lon, display_name, address details
- Self-host: docker run -p 8080:8080 nominatim

**Map matching (route from GPS points):**
- OSRM matching API: https://router.project-osrm.org/match/v1/foot/{coordinates}
- Snaps GPS points to road network
- Returns cleaned route geometry

### Architecture for local/offline maps:
1. Download OSM PBF file for your city (e.g. geofabrik.de)
2. Self-host OSRM + Nominatim in Docker on your PC
3. flutter_map loads tiles from OSM (or self-hosted tile server)
4. Directions from local OSRM (no API key, no cost)
5. Search from local Nominatim
6. Everything runs on your PC — no Google, no Mapbox, no API keys
