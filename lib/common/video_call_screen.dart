import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String token;
  final String currentUserId;
  final String currentUserName;
  final String otherUserName;
  final bool isVideoCall;
  final String roomId;
  final String? bookingEndTime; // Format: "HH:mm:ss" or "HH:mm"

  const VideoCallScreen({
    Key? key,
    required this.channelName,
    required this.token,
    required this.currentUserId,
    required this.currentUserName,
    required this.otherUserName,
    required this.isVideoCall,
    required this.roomId,
    this.bookingEndTime,
  }) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late RtcEngine _engine;
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  bool _isSharingScreen = false;
  Timer? _callTimer;
  int _callDuration = 0;
  Timer? _bookingTimeChecker;
  bool _isTimeExpired = false;
  Timer? _connectionTimeout;
  bool _showedConnectionWarning = false;

  @override
  void initState() {
    super.initState();
    _initializeAgora();
    _startCallTimer();
    _startBookingTimeChecker();
    _startConnectionTimeout();
    WakelockPlus.enable();
  }

  void _startConnectionTimeout() {
    // Show warning after 10 seconds if remote user hasn't joined
    _connectionTimeout = Timer(const Duration(seconds: 10), () {
      if (_remoteUid == null && mounted && !_showedConnectionWarning) {
        _showedConnectionWarning = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Koneksi lambat. Video call bekerja lebih baik di aplikasi Android/iOS.',
              style: TextStyle(fontSize: 12),
            ),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  Future<void> _initializeAgora() async {
    print('🎥 Initializing Agora...');
    print('   - Channel: ${widget.channelName}');
    print('   - Video: ${widget.isVideoCall}');
    print('   - User: ${widget.currentUserId}');
    
    // Request permissions
    if (widget.isVideoCall) {
      await [Permission.microphone, Permission.camera].request();
    } else {
      await [Permission.microphone].request();
    }

    // Create RTC engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: '6ac6f6dc56b941d19e409d96ca518d5f', // TODO: Replace with your Agora App ID
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print('✅ Local user ${connection.localUid} joined channel ${connection.channelId}');
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print('✅ Remote user $remoteUid joined');
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          print('❌ Remote user $remoteUid left channel (reason: $reason)');
          setState(() {
            _remoteUid = null;
          });
        },
        onError: (ErrorCodeType err, String msg) {
          print('❌ Agora Error: $err - $msg');
        },
      ),
    );

    if (widget.isVideoCall) {
      await _engine.enableVideo();
      await _engine.startPreview();
    } else {
      await _engine.disableVideo();
    }

    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration++;
      });
    });
  }

  void _startBookingTimeChecker() {
    if (widget.bookingEndTime == null) return;

    // Parse booking end time
    try {
      final parts = widget.bookingEndTime!.split(':');
      final endHour = int.parse(parts[0]);
      final endMinute = int.parse(parts[1]);
      
      // Check every 5 seconds if current time >= end time
      _bookingTimeChecker = Timer.periodic(const Duration(seconds: 5), (timer) {
        final now = DateTime.now();
        final currentMinutes = now.hour * 60 + now.minute;
        final endMinutes = endHour * 60 + endMinute;
        
        print('🕒 Time check: ${now.hour}:${now.minute} vs end ${endHour}:${endMinute}');
        
        // End call if current time >= booking end time
        if (currentMinutes >= endMinutes && !_isTimeExpired) {
          print('⏰ Booking time expired! Auto-ending call...');
          _isTimeExpired = true;
          _showTimeExpiredDialog();
        }
      });
      
      print('📅 Booking end time set to: ${widget.bookingEndTime}');
    } catch (e) {
      print('❌ Error parsing booking end time: $e');
    }
  }

  void _showTimeExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.access_time, color: Colors.orange[700]),
            const SizedBox(width: 10),
            const Text('Waktu Sesi Berakhir'),
          ],
        ),
        content: const Text(
          'Waktu booking Anda telah berakhir. Call akan otomatis diakhiri.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _endCall(); // End the call
            },
            child: const Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _endCall() async {
    // Update call status in Firebase
    await FirebaseDatabase.instance
        .ref('calls/${widget.roomId}')
        .update({'status': 'ended'});

    Navigator.of(context).pop();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _engine.muteLocalAudioStream(_isMuted);
  }

  void _toggleCamera() {
    if (!widget.isVideoCall) return;
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
    _engine.muteLocalVideoStream(_isCameraOff);
  }

  void _switchCamera() {
    if (!widget.isVideoCall) return;
    _engine.switchCamera();
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    _engine.setEnableSpeakerphone(_isSpeakerOn);
  }

  Future<void> _toggleScreenShare() async {
    if (_isSharingScreen) {
      // Stop screen sharing
      await _engine.stopScreenCapture();
      // Re-enable camera if it was on before
      if (!_isCameraOff) {
        await _engine.enableLocalVideo(true);
      }
      setState(() {
        _isSharingScreen = false;
      });
      print('📱 Screen sharing stopped');
    } else {
      // Start screen sharing
      try {
        // Disable camera first
        await _engine.enableLocalVideo(false);
        
        // Start screen capture
        await _engine.startScreenCapture(
          const ScreenCaptureParameters2(
            captureAudio: true,
            captureVideo: true,
          ),
        );
        
        setState(() {
          _isSharingScreen = true;
        });
        print('📱 Screen sharing started');
        
        // Show notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Screen sharing dimulai'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('❌ Error starting screen share: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memulai screen sharing: $e'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _bookingTimeChecker?.cancel();
    _connectionTimeout?.cancel();
    if (_isSharingScreen) {
      _engine.stopScreenCapture();
    }
    _engine.leaveChannel();
    _engine.release();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video or audio-only background
          Center(
            child: _remoteUid != null && widget.isVideoCall
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine,
                      canvas: VideoCanvas(uid: _remoteUid),
                      connection: RtcConnection(channelId: widget.channelName),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue,
                        child: Text(
                          widget.otherUserName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 48,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.otherUserName,
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _remoteUid != null ? 'Connected' : 'Calling...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
          ),

          // Local video (picture-in-picture)
          if (widget.isVideoCall && _localUserJoined && !_isCameraOff)
            Positioned(
              top: 60,
              right: 20,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),

          // Top bar with call duration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 50, bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _formatDuration(_callDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _isSharingScreen 
                        ? 'Sharing Screen' 
                        : widget.isVideoCall ? 'Video Call' : 'Voice Call',
                    style: TextStyle(
                      color: _isSharingScreen ? Colors.green : Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: _isSharingScreen ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute button
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    onTap: _toggleMute,
                    backgroundColor:
                        _isMuted ? Colors.red : Colors.white.withOpacity(0.3),
                  ),

                  // Camera toggle (video call only)
                  if (widget.isVideoCall && !_isSharingScreen)
                    _buildControlButton(
                      icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                      onTap: _toggleCamera,
                      backgroundColor: _isCameraOff
                          ? Colors.red
                          : Colors.white.withOpacity(0.3),
                    ),

                  // Screen share button (video call only)
                  if (widget.isVideoCall)
                    _buildControlButton(
                      icon: _isSharingScreen ? Icons.stop_screen_share : Icons.screen_share,
                      onTap: _toggleScreenShare,
                      backgroundColor: _isSharingScreen
                          ? Colors.green
                          : Colors.white.withOpacity(0.3),
                    ),

                  // End call button
                  _buildControlButton(
                    icon: Icons.call_end,
                    onTap: _endCall,
                    backgroundColor: Colors.red,
                    size: 70,
                  ),

                  // Speaker toggle
                  _buildControlButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                    onTap: _toggleSpeaker,
                    backgroundColor: Colors.white.withOpacity(0.3),
                  ),

                  // Switch camera (video call only)
                  if (widget.isVideoCall && !_isSharingScreen)
                    _buildControlButton(
                      icon: Icons.cameraswitch,
                      onTap: _switchCamera,
                      backgroundColor: Colors.white.withOpacity(0.3),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color backgroundColor,
    double size = 56,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.45,
        ),
      ),
    );
  }
}
