import 'adaptive_stream_info_parser.dart';
import 'muxed_stream_info_parser.dart';
import 'dart:convert';

class VideoInfoParser {
  Map<String, String> _root;
  bool isLive;
  dynamic _playerResponseJson;

  VideoInfoParser(this._root) {
    _playerResponseJson = jsonDecode(_root['player_response']);
  }

  String parseStatus() => _root['status'];

  // String parseId() => _root["video_id"]; // no longer provided

  int parseErrorCode() =>
      _root['errorcode'] == null ? 0 : int.tryParse(_root['errorcode']);

  String parseErrorReason() => _root["reason"];

  String parsePreviewVideoId() => _root['ypc_vid'];

  String parseDashManifestUrl() =>
      _playerResponseJson['streamingData']['dashManifestUrl'];

  String parseHlsPlaylistUrl() =>
      _playerResponseJson['streamingData']['hlsManifestUrl'];

  List<MuxedStreamInfoParser> getMuxedStreamInfo() {
    var streamInfosEncoded = _root['url_encoded_fmt_stream_map'];

    if (streamInfosEncoded == null) {
      return List<MuxedStreamInfoParser>();
    }

    // List that we will full
    var builtList = List<MuxedStreamInfoParser>();

    // Extract the streams and return a list
    var streams = streamInfosEncoded.split(',');
    streams.forEach((stream) {
      builtList.add(MuxedStreamInfoParser(Uri.splitQueryString(stream)));
    });

    return builtList;
  }

  List<AdaptiveStreamInfoParser> getAdaptiveStreamInfo() {
    var streamInfosEncoded = _root['adaptive_fmts'];

    if (streamInfosEncoded == null) {
      return List<AdaptiveStreamInfoParser>();
    }

    // List that we will full
    var builtList = List<AdaptiveStreamInfoParser>();

    // Extract the streams and return a list
    var streams = streamInfosEncoded.split(',');
    streams.forEach((stream) {
      builtList.add(AdaptiveStreamInfoParser(Uri.splitQueryString(stream)));
    });

    return builtList;
  }

  List<MuxedStreamInfoParser> getMuxedStreamInfoFromJson() {
    List<dynamic> formats = _playerResponseJson['streamingData']['formats'];

    // List that we will full
    var builtList = List<MuxedStreamInfoParser>();

    if (formats == null || formats.length == 0) {
      return builtList;
    }

    formats.forEach((format) {
      Map<String, String> parserParams = Map<String, String>();
      parserParams['itag'] = format['itag']?.toString();
      parserParams['url'] = format['url'];

      if (parserParams['url'] == null || parserParams['url'].isEmpty) {
        String cipher = format['cipher'];
        Map<String, String> cipherMap = Uri.splitQueryString(cipher);
        parserParams['url'] = cipherMap['url'];
        parserParams['s'] = cipherMap['s'];
      }

      builtList.add(MuxedStreamInfoParser(parserParams));
    });

    return builtList;
  }

  static VideoInfoParser initialize(String raw) {
    var root = Uri.splitQueryString(raw);
    return VideoInfoParser(root);
  }
}
