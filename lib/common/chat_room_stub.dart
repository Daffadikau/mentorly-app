import 'package:flutter/material.dart';

// Stub implementation for non-web platforms
Widget buildWebImage(String url, {VoidCallback? onTap}) {
  return Image.network(url, fit: BoxFit.contain);
}

Widget buildWebFile(String url, String fileName, {VoidCallback? onTap}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.insert_drive_file, color: Colors.blue[700]),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            fileName,
            style: const TextStyle(color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
