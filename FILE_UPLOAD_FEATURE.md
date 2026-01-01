# Chat File Upload Feature

## Overview
Added complete image and file upload functionality to the chat system, allowing both mentors and pelajar to share files during conversations.

## Features Implemented

### 1. Image Upload
- **Source**: Gallery/Photos
- **Package**: image_picker ^1.0.7
- **Supported formats**: JPG, PNG (automatically optimized)
- **Max resolution**: 1920x1080 at 85% quality
- **Display**: Inline images in chat bubbles with loading indicators

### 2. Document Upload
- **Package**: file_picker ^6.1.0
- **Supported formats**: PDF, DOC, DOCX, XLS, XLSX, PPT, PPTX, TXT
- **Display**: File icon with filename, tap to open

### 3. Firebase Storage Integration
- **Path structure**: `chat_files/{room_id}/{timestamp}_{filename}`
- **Upload monitoring**: Real-time progress indicator (0-100%)
- **Download URLs**: Stored in message data for retrieval

### 4. Enhanced Message Structure
```dart
{
  'sender_id': string,
  'sender_type': 'mentor' | 'pelajar',
  'message': string,  // Text or file description
  'file_url': string?,  // Download URL if file attached
  'file_name': string?,  // Original filename
  'file_type': 'text' | 'image' | 'file',
  'timestamp': int,
  'read': bool
}
```

### 5. UI Components

#### Attachment Button
- Location: Next to text input field
- Icon: Paperclip (📎)
- Action: Opens bottom sheet with options
- States: Active/Disabled during upload

#### Bottom Sheet Options
- **Gambar dari Galeri**: Opens gallery picker
- **Dokumen**: Opens file browser

#### Upload Progress
- Linear progress bar above input field
- Percentage display (0-100%)
- Disables attachment button during upload

#### Message Bubbles
- **Text messages**: Original design preserved
- **Images**: Displayed inline, 250px width, rounded corners
  - Loading: CircularProgressIndicator
  - Error: Broken image icon
- **Files**: Icon + filename with "Tap untuk membuka"
  - Tappable to open/download

### 6. Last Message Updates
In chat_rooms list:
- Text: Shows actual message
- Image: "📷 Gambar"
- File: "📎 File"

## Technical Implementation

### Imports Added
```dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
```

### Key Methods

1. **_pickAndSendImage()**
   - Uses ImagePicker to select photo
   - Applies quality compression
   - Calls upload method

2. **_pickAndSendFile()**
   - Uses FilePicker for documents
   - Filters by allowed extensions
   - Calls upload method

3. **_uploadAndSendFile(file, type)**
   - Converts file to Uint8List
   - Uploads to Firebase Storage with progress
   - Gets download URL
   - Saves message to RTDB
   - Updates chat room last_message

### State Management
```dart
bool isUploading = false;
double uploadProgress = 0.0;
```

## Platform Support

### Web (kIsWeb = true)
- Uses PlatformFile.bytes directly
- No file path needed
- Image picker uses web file selector

### Mobile (iOS/Android)
- Reads file from path using dart:io
- Native gallery/file pickers

## Error Handling

1. **Picker cancellation**: Silent (no error shown)
2. **Upload failures**: SnackBar with error message
3. **Image load errors**: Shows broken image icon
4. **Invalid file types**: Exception with user feedback

## Usage Flow

### For Users:
1. Open chat with mentor/pelajar
2. Tap paperclip icon (📎)
3. Choose "Gambar dari Galeri" or "Dokumen"
4. Select file from device
5. Wait for upload (progress shown)
6. File appears in chat immediately

### For Developers:
```dart
// Example: Manually sending a file message
await _database.child('messages').child(roomId).push().set({
  'sender_id': userId,
  'sender_type': userType,
  'message': '📷 Gambar',
  'file_url': downloadUrl,
  'file_name': 'photo.jpg',
  'file_type': 'image',
  'timestamp': DateTime.now().millisecondsSinceEpoch,
  'read': false,
});
```

## Testing Checklist

- [x] Select image from gallery
- [x] Upload progress displays correctly
- [x] Image shows inline in chat
- [x] Select PDF document
- [x] File shows with icon and name
- [x] Tap file to open (web)
- [x] Both mentor and pelajar can send/receive
- [x] Last message updates in chat list
- [x] Error handling for failed uploads
- [x] Works on web platform

## Files Modified

1. **lib/common/chat_room.dart**
   - Added imports (7 new)
   - Added state variables (isUploading, uploadProgress)
   - Added _pickAndSendImage() method
   - Added _pickAndSendFile() method
   - Added _uploadAndSendFile() method
   - Updated _buildMessageBubble() for file display
   - Updated input area with attachment button
   - Added upload progress indicator

2. **pubspec.yaml**
   - Added image_picker: ^1.0.7

## Dependencies

```yaml
firebase_storage: ^12.0.0  # Already existed
file_picker: ^6.1.0  # Already existed
image_picker: ^1.0.7  # Newly added
```

## Future Enhancements

- [ ] File size limits (e.g., max 10MB)
- [ ] Image compression options
- [ ] Video upload support
- [ ] Voice message recording
- [ ] File download progress
- [ ] Image preview before sending
- [ ] Multiple file selection
- [ ] Delete sent files
- [ ] Storage usage tracking

## Notes

- Firebase Storage security rules should be configured properly
- Consider adding file size validation before upload
- Storage costs may increase with heavy usage
- Images are automatically optimized for chat display
- Web platform uses browser's native file picker
