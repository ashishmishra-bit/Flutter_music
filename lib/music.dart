import 'dart:async';
import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_media_notification/flutter_media_notification.dart';
import 'package:gradient_widgets/gradient_widgets.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'API/saavn.dart';

String status = 'hidden';
Color accent = Color(0xff61e88a);
Color accent_light = Colors.lightGreen[50];
AudioPlayer audioPlayer;
PlayerState playerState;

typedef void OnError(Exception exception);

enum PlayerState { stopped, playing, paused }

class AudioApp extends StatefulWidget {
  @override
  AudioAppState createState() => AudioAppState();
}

@override
class AudioAppState extends State<AudioApp> {
  Duration duration;
  Duration position;

  get isPlaying => playerState == PlayerState.playing;
  get isPaused => playerState == PlayerState.paused;

  get durationText => duration != null ? duration.toString().split('.').first : '';

  get positionText => position != null ? position.toString().split('.').first : '';

  bool isMuted = false;

  StreamSubscription _positionSubscription;
  StreamSubscription _audioPlayerStateSubscription;

  @override
  void initState() {
    super.initState();

    initAudioPlayer();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void initAudioPlayer() {
    if (audioPlayer == null) {
      audioPlayer = AudioPlayer();
    }
    setState(() {
      if (checker == "Haa") {
        stop();
        play();
      }
      if (checker == "Nahi") {
        play();
      }
    });

    _positionSubscription = audioPlayer.onAudioPositionChanged.listen((p) => setState(() => position = p));

    _audioPlayerStateSubscription = audioPlayer.onPlayerStateChanged.listen((s) {
      if (s == AudioPlayerState.PLAYING) {
        setState(() => duration = audioPlayer.duration);
      } else if (s == AudioPlayerState.STOPPED) {
        onComplete();
        setState(() {
          position = duration;
        });
      }
    }, onError: (msg) {
      setState(() {
        playerState = PlayerState.stopped;
        duration = Duration(seconds: 0);
        position = Duration(seconds: 0);
      });
    });
  }

  Future play() async {
    await audioPlayer.play(kUrl);
    MediaNotification.showNotification(title: title, author: artist, artUri: image, isPlaying: true);

    setState(() {
      playerState = PlayerState.playing;
    });
  }

  Future pause() async {
    await audioPlayer.pause();
    MediaNotification.showNotification(title: title, author: artist, artUri: image, isPlaying: false);
    setState(() {
      playerState = PlayerState.paused;
    });
  }

  Future stop() async {
    await audioPlayer.stop();
    setState(() {
      playerState = PlayerState.stopped;
      position = Duration();
    });
  }

  Future mute(bool muted) async {
    await audioPlayer.mute(muted);
    setState(() {
      isMuted = muted;
    });
  }

  void onComplete() {
    setState(() => playerState = PlayerState.stopped);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff384850),
            Color(0xff263238),
            Color(0xff263238),
            //Color(0xff61e88a),
          ],
        ),
      ),
      child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            brightness: Brightness.dark,
            backgroundColor: Colors.transparent,
            elevation: 0,
            //backgroundColor: Color(0xff384850),
            centerTitle: true,
            title: GradientText(
              "Now Playing",
              shaderRect: Rect.fromLTWH(13.0, 0.0, 100.0, 50.0),
              gradient: LinearGradient(colors: [
                Color(0xff4db6ac),
                Color(0xff61e88a),
              ]),
              style: TextStyle(color: accent, fontSize: 25, fontWeight: FontWeight.w700),
            ),
            leading: Padding(
              padding: const EdgeInsets.only(left: 14.0),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  size: 28,
                  color: accent,
                ),
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
          ),
          body: new Center(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: [
                  new Container(
                      width: 350,
                      height: 350,
                      decoration: new BoxDecoration(borderRadius: BorderRadius.circular(8), shape: BoxShape.rectangle, image: new DecorationImage(fit: BoxFit.fill, image: new NetworkImage(image)))),
                  Padding(
                    padding: const EdgeInsets.only(top: 35.0, bottom: 35),
                    child: Column(
                      children: <Widget>[
                        new GradientText(
                          title,
                          shaderRect: Rect.fromLTWH(13.0, 0.0, 100.0, 50.0),
                          gradient: LinearGradient(colors: [
                            Color(0xff4db6ac),
                            Color(0xff61e88a),
                          ]),
                          textScaleFactor: 2.5,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(album + "  |  " + artist, style: TextStyle(color: accent_light, fontSize: 15, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                  Material(child: _buildPlayer()),
                ],
              ),
            ),
          )),
    );
  }

  Widget _buildPlayer() => Container(
        padding: EdgeInsets.only(top: 15.0, left: 16, right: 16, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (duration != null)
              Slider(
                  activeColor: accent,
                  inactiveColor: Colors.green[50],
                  value: position?.inMilliseconds?.toDouble() ?? 0.0,
                  onChanged: (double value) {
                    return audioPlayer.seek((value / 1000).roundToDouble());
                  },
                  min: 0.0,
                  max: duration.inMilliseconds.toDouble()),
            if (position != null) _buildProgressView(),
            Padding(
              padding: const EdgeInsets.only(top: 18.0),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      isPlaying
                          ? Container()
                          : Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xff4db6ac),
                                      //Color(0xff00c754),
                                      Color(0xff61e88a),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(100)),
                              child: IconButton(
                                onPressed: isPlaying ? null : () => play(),
                                iconSize: 40.0,
                                icon: Padding(
                                  padding: const EdgeInsets.only(left: 2.2),
                                  child: Icon(MdiIcons.playOutline),
                                ),
                                color: Color(0xff263238),
                              ),
                            ),
                      isPlaying
                          ? Container(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xff4db6ac),
                                      //Color(0xff00c754),
                                      Color(0xff61e88a),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(100)),
                              child: IconButton(
                                onPressed: isPlaying ? () => pause() : null,
                                iconSize: 40.0,
                                icon: Icon(MdiIcons.pause),
                                color: Color(0xff263238),
                              ),
                            )
                          : Container()
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: Builder(builder: (context) {
                      return FlatButton(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
                          color: Colors.black12,
                          onPressed: () {
                            showBottomSheet(
                                context: context,
                                builder: (context) => Container(
                                      decoration:
                                          new BoxDecoration(color: Color(0xff212c31), borderRadius: new BorderRadius.only(topLeft: const Radius.circular(18.0), topRight: const Radius.circular(18.0))),
                                      height: 400,
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.only(top: 10.0),
                                              child: Row(
                                                children: <Widget>[
                                                  IconButton(
                                                      icon: Icon(
                                                        Icons.arrow_back_ios,
                                                        color: accent,
                                                        size: 20,
                                                      ),
                                                      onPressed: () => {Navigator.pop(context)}),
                                                  Text(
                                                    "Lyrics",
                                                    style: TextStyle(
                                                      color: accent,
                                                      fontSize: 30,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            lyrics != "null"
                                                ? Padding(
                                                    padding: const EdgeInsets.all(6.0),
                                                    child: Container(
                                                      child: new Text(
                                                        lyrics,
                                                        style: new TextStyle(
                                                          fontSize: 16.0,
                                                          color: accent_light,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                      ),
                                                    ))
                                                : Padding(
                                                    padding: const EdgeInsets.only(top: 120.0),
                                                    child: Center(
                                                      child: Container(
                                                        child: Text(
                                                          "No Lyrics available ;(",
                                                          style: TextStyle(color: accent_light, fontSize: 25),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                          ],
                                        ),
                                      ),
                                    ));
                          },
                          child: Text(
                            "Lyrics",
                            style: TextStyle(color: accent),
                          ));
                    }),
                  )
                ],
              ),
            ),
          ],
        ),
      );

  Row _buildProgressView() => Row(mainAxisSize: MainAxisSize.min, children: [
        Text(
          position != null ? "${positionText ?? ''} ".replaceFirst("0:0", "0") : duration != null ? durationText : '',
          style: TextStyle(fontSize: 18.0, color: Colors.green[50]),
        ),
        Spacer(),
        Text(
          position != null ? "${durationText ?? ''}".replaceAll("0:", "") : duration != null ? durationText : '',
          style: TextStyle(fontSize: 18.0, color: Colors.green[50]),
        )
      ]);
}