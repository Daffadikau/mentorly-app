import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Optimized circular avatar with cached images for better performance
class CachedCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData fallbackIcon;
  final Color? backgroundColor;
  final Color? iconColor;

  const CachedCircleAvatar({
    Key? key,
    this.imageUrl,
    this.radius = 20,
    this.fallbackIcon = Icons.person,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[300],
        child: Icon(
          fallbackIcon,
          size: radius,
          color: iconColor ?? Colors.grey[600],
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[300],
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => Icon(
            fallbackIcon,
            size: radius,
            color: iconColor ?? Colors.grey[600],
          ),
          errorWidget: (context, url, error) => Icon(
            fallbackIcon,
            size: radius,
            color: iconColor ?? Colors.grey[600],
          ),
          memCacheWidth: (radius * 2 * 3).toInt(), // 3x device pixel ratio
          memCacheHeight: (radius * 2 * 3).toInt(),
          maxWidthDiskCache: (radius * 2 * 3).toInt(),
          maxHeightDiskCache: (radius * 2 * 3).toInt(),
        ),
      ),
    );
  }
}
