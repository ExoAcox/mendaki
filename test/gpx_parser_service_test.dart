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
}

