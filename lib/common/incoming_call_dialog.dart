import 'package:flutter/material.dart';

class IncomingCallDialog extends StatelessWidget {
  final String callerName;
  final bool isVideoCall;
  final String roomId;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingCallDialog({
    Key? key,
    required this.callerName,
    required this.isVideoCall,
    required this.roomId,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVideoCall ? Icons.videocam : Icons.phone,
                size: 48,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 20),

            // Caller name
            Text(
              callerName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Call type
            Text(
              isVideoCall ? 'Incoming Video Call' : 'Incoming Voice Call',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // Action buttons
            Row(
              children: [
                // Reject button
                Expanded(
                  child: ElevatedButton(
                    onPressed: onReject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.call_end, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Reject',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Accept button
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isVideoCall ? Icons.videocam : Icons.phone,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Accept',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
