import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;

// Web-specific image widget using HTML img element
Widget buildWebImage(String url, {VoidCallback? onTap}) {
  final html.ImageElement imgElement = html.ImageElement()
    ..src = url
    ..style.maxWidth = '100%'
    ..style.maxHeight = '100%'
    ..style.width = 'auto'
    ..style.height = 'auto'
    ..style.objectFit = 'contain'
    ..style.display = 'block'
    ..style.margin = 'auto'
    ..style.borderRadius = '18px'
    ..style.cursor = 'pointer'
    ..onClick.listen((event) {
      if (onTap != null) onTap();
    });

  final String viewType = 'image-${url.hashCode}-${DateTime.now().millisecondsSinceEpoch}';

  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) => imgElement,
  );

  return SizedBox(
    height: 300,
    child: HtmlElementView(viewType: viewType),
  );
}

// Web-specific file widget
Widget buildWebFile(String url, String fileName, {VoidCallback? onTap}) {
  return InkWell(
    onTap: () {
      html.window.open(url, '_blank');
    },
    child: Container(
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
          const SizedBox(width: 8),
          const Icon(Icons.download, size: 16, color: Colors.grey),
        ],
      ),
    ),
  );
}
