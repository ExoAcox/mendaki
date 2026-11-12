import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mendaki/core/services/gpx_parser_service.dart';
import 'package:mendaki/models/waypoint.dart';

void main() {
  group('Waypoint 4-Type & Tag <cmt> Classification Tests', () {
    test('Waypoint getters only evaluate comment or type, ignoring name guesses', () {
      // Sabana without comment should be post, NOT camp
      const sabanaWpt = Waypoint(
        name: 'Sabana 1',
        latitude: -7.45,
        longitude: 110.44,
      );
      expect(sabanaWpt.type, 'post');
      expect(sabanaWpt.isCamp, isFalse);
      expect(sabanaWpt.isBasecamp, isFalse);
      expect(sabanaWpt.isSummit, isFalse);
      expect(sabanaWpt.isPost, isTrue);

      // Puncak without comment should be post, NOT summit
      const puncakWpt = Waypoint(
        name: 'Puncak Kenteng Songo',
        latitude: -7.45,
        longitude: 110.44,
      );
      expect(puncakWpt.isSummit, isFalse);
      expect(puncakWpt.isPost, isTrue);

      // Basecamp without comment should be post, NOT basecamp
      const bcWpt = Waypoint(
        name: 'Basecamp Selo',
        latitude: -7.45,
        longitude: 110.44,
      );
      expect(bcWpt.isBasecamp, isFalse);
      expect(bcWpt.isPost, isTrue);

      // Explicit comments
      const explicitCamp = Waypoint(
        name: 'Sabana 2',
        latitude: -7.45,
        longitude: 110.44,
        comment: 'camp',
      );
      expect(explicitCamp.isCamp, isTrue);
      expect(explicitCamp.isPost, isFalse);

      const explicitBc = Waypoint(
        name: 'Selo',
        latitude: -7.45,
        longitude: 110.44,
        comment: 'basecamp',
      );
      expect(explicitBc.isBasecamp, isTrue);

      const explicitSummit = Waypoint(
        name: 'Triangulasi',
        latitude: -7.45,
        longitude: 110.44,
        comment: 'summit',
      );
      expect(explicitSummit.isSummit, isTrue);
    });

    test('GpxParserService parses exactly 4 types strictly from <cmt> tag', () {
      const gpxContent = '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="Mendaki">
  <metadata><name>Merbabu Selo</name></metadata>
  <wpt lat="-7.50" lon="110.45">
    <name>Basecamp Selo</name>
    <cmt>basecamp</cmt>
  </wpt>
  <wpt lat="-7.47" lon="110.44">
    <name>Sabana 1</name>
  </wpt>
  <wpt lat="-7.46" lon="110.44">
    <name>Sabana 2</name>
    <cmt>camp</cmt>
  </wpt>
  <wpt lat="-7.45" lon="110.43">
    <name>Puncak Triangulasi</name>
    <cmt>summit</cmt>
  </wpt>
  <wpt lat="-7.44" lon="110.43">
    <name>Puncak Kenteng Songo</name>
  </wpt>
  <trk>
    <name>Jalur Selo</name>
    <trkseg>
      <trkpt lat="-7.50" lon="110.45"><ele>1800</ele></trkpt>
      <trkpt lat="-7.45" lon="110.43"><ele>3145</ele></trkpt>
    </trkseg>
  </trk>
</gpx>''';

      final result = GpxParserService.parseString(gpxContent);
      expect(result.waypoints.length, 5);

      // Basecamp with <cmt>basecamp</cmt>
      final bc = result.waypoints[0];
      expect(bc.type, 'basecamp');
      expect(bc.isBasecamp, isTrue);

      // Sabana 1 without <cmt> -> post
      final sabana1 = result.waypoints[1];
      expect(sabana1.type, 'post');
      expect(sabana1.isCamp, isFalse);
      expect(sabana1.isPost, isTrue);

      // Sabana 2 with <cmt>camp</cmt> -> camp
      final sabana2 = result.waypoints[2];
      expect(sabana2.type, 'camp');
      expect(sabana2.isCamp, isTrue);

      // Puncak Triangulasi with <cmt>summit</cmt> -> summit
      final summit = result.waypoints[3];
      expect(summit.type, 'summit');
      expect(summit.isSummit, isTrue);

      // Puncak Kenteng Songo without <cmt> -> post
      final summitNoCmt = result.waypoints[4];
      expect(summitNoCmt.type, 'post');
      expect(summitNoCmt.isSummit, isFalse);
      expect(summitNoCmt.isPost, isTrue);
    });
  });

  group('Hybrid GPX (<rte>, <trk>, <wpt>) Parsing Tests', () {
    test('Parses routes from <rte> and extracts waypoints from <rtept>', () {
      const gpxRouteContent = '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="Garmin BaseCamp">
  <metadata><name>Rute Lawu Candi Cetho</name></metadata>
  <rte>
    <name>Jalur Candi Cetho</name>
    <rtept lat="-7.595" lon="111.155">
      <ele>1450</ele>
      <name>Basecamp Candi Cetho</name>
      <cmt>basecamp</cmt>
    </rtept>
    <rtept lat="-7.610" lon="111.175">
      <ele>2400</ele>
      <name>Pos 3 Candi Kethek</name>
      <cmt>post</cmt>
    </rtept>
    <rtept lat="-7.625" lon="111.192">
      <ele>2800</ele>
      <name>Gupakan Menjangan</name>
      <cmt>camp</cmt>
    </rtept>
    <rtept lat="-7.628" lon="111.195">
      <ele>3265</ele>
      <name>Puncak Hargo Dumilah</name>
      <cmt>summit</cmt>
    </rtept>
  </rte>
</gpx>''';

      final result = GpxParserService.parseString(gpxRouteContent);

      // Pastikan route terbentuk dari <rte>
      expect(result.tracks.length, 1);
      final route = result.tracks.first;
      expect(route.name, 'Jalur Candi Cetho');
      expect(route.trackPoints.length, 4);
      expect(route.distanceKm, greaterThan(0));
      expect(route.elevationGainMeters, greaterThan(1000));

      // Pastikan waypoints diekstrak otomatis dari <rtept>
      expect(result.waypoints.length, 4);
      expect(result.waypoints[0].name, 'Basecamp Candi Cetho');
      expect(result.waypoints[0].type, 'basecamp');
      expect(result.waypoints[1].name, 'Pos 3 Candi Kethek');
      expect(result.waypoints[1].type, 'post');
      expect(result.waypoints[2].name, 'Gupakan Menjangan');
      expect(result.waypoints[2].type, 'camp');
      expect(result.waypoints[3].name, 'Puncak Hargo Dumilah');
      expect(result.waypoints[3].type, 'summit');

      // Basecamp rute terdeteksi otomatis
      expect(route.basecampName, 'Basecamp Candi Cetho');
    });

    test('Parses both <trk> and distinct <rte> in hybrid GPX', () {
      const gpxHybridContent = '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1">
  <metadata><name>Sumbing Multi-Route</name></metadata>
  <wpt lat="-7.384" lon="110.070">
    <name>Basecamp Bowongso</name>
    <cmt>basecamp</cmt>
  </wpt>
  <trk>
    <name>Jalur Garung</name>
    <trkseg>
      <trkpt lat="-7.370" lon="110.050"><ele>1600</ele></trkpt>
      <trkpt lat="-7.380" lon="110.060"><ele>2500</ele></trkpt>
      <trkpt lat="-7.384" lon="110.070"><ele>3371</ele></trkpt>
    </trkseg>
  </trk>
  <rte>
    <name>Jalur Adipuro</name>
    <rtept lat="-7.400" lon="110.090"><ele>1700</ele></rtept>
    <rtept lat="-7.390" lon="110.080"><ele>2600</ele></rtept>
    <rtept lat="-7.384" lon="110.070"><ele>3371</ele></rtept>
  </rte>
</gpx>''';

      final result = GpxParserService.parseString(gpxHybridContent);

      // Ada 2 rute berbeda: Jalur Garung (<trk>) dan Jalur Adipuro (<rte>)
      expect(result.tracks.length, 2);
      expect(result.tracks[0].name, 'Jalur Garung');
      expect(result.tracks[1].name, 'Jalur Adipuro');
      expect(result.waypoints.length, 1);
    });

    test('Fallback route generated when GPX only contains ordered <wpt> without trk or rte', () {
      const gpxWptOnlyContent = '''<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1">
  <metadata><name>Jalur Waypoint Saja</name></metadata>
  <wpt lat="-7.10" lon="110.10"><name>Basecamp</name><cmt>basecamp</cmt><ele>1200</ele></wpt>
  <wpt lat="-7.12" lon="110.12"><name>Pos 1</name><cmt>post</cmt><ele>1800</ele></wpt>
  <wpt lat="-7.15" lon="110.15"><name>Puncak</name><cmt>summit</cmt><ele>2500</ele></wpt>
</gpx>''';

      final result = GpxParserService.parseString(gpxWptOnlyContent);

      // Rute dibuat otomatis dari waypoints
      expect(result.tracks.length, 1);
      final fallbackRoute = result.tracks.first;
      expect(fallbackRoute.name, 'Jalur Waypoint Saja');
      expect(fallbackRoute.trackPoints.length, 3);
      expect(fallbackRoute.trackPoints.first.latitude, -7.10);
      expect(fallbackRoute.trackPoints.last.latitude, -7.15);
      expect(fallbackRoute.distanceKm, greaterThan(0));
    });

    test('Parses sindoro.gpx with verified basecamps, camps, and summit', () async {
      final file = File('sindoro.gpx');
      if (file.existsSync()) {
        final result = await GpxParserService.parseFile(file);
        final basecamps = result.waypoints.where((w) => w.isBasecamp).toList();
        final camps = result.waypoints.where((w) => w.isCamp).toList();
        final summits = result.waypoints.where((w) => w.isSummit).toList();

        expect(basecamps.length, equals(8));
        expect(camps.length, equals(10));
        expect(summits.length, equals(1));
        expect(summits.first.name, equals('PUNCAK 3151 MDPL'));
        expect(camps.map((w) => w.name), containsAll([
          'CAMP',
          'SUNRISE CAMP',
        ]));

        // Verifikasi rute bedakah tersambung utuh dari basecamp hingga atas
        final bedakahRoute = result.tracks.firstWhere(
          (t) => t.name.toLowerCase() == 'bedakah',
        );
        expect(bedakahRoute.trackPoints.length, greaterThanOrEqualTo(150));
        expect(bedakahRoute.distanceKm, greaterThan(6.0));
        expect(bedakahRoute.basecampName, equals('BASECAMP BEDAKAH'));

        // Verifikasi rute alang sewu mengambil jalur utama lengkap dari basecamp
        final alangSewuRoute = result.tracks.firstWhere(
          (t) => t.name.toLowerCase() == 'alang sewu',
        );
        expect(alangSewuRoute.trackPoints.length, greaterThan(400));
        expect(alangSewuRoute.distanceKm, greaterThan(6.0));
        expect(alangSewuRoute.basecampName, equals('BASECAMP ALANG-ALANG SEWU'));
      }
    });
  });
}

