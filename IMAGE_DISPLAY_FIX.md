# Fix for Image Not Displaying in Chat

## Problem
Images are uploading successfully to Firebase Storage, but not displaying in the chat. You see a broken image icon instead.

## Root Cause
Firebase Storage CORS (Cross-Origin Resource Sharing) is not configured to allow requests from your web app domain.

## Solution

### Option 1: Using Firebase Console (Easiest)

1. Go to https://console.firebase.google.com/
2. Select project: **mentorly-66d07**
3. Go to **Storage** → **Files**
4. Check if images are there in `chat_files/` folder
5. Click on an image and copy the download URL
6. Try opening it in a new browser tab
   - If it shows 403 error or CORS error → CORS needs configuration
   - If it loads → Check image URL in code

### Option 2: Update Storage Rules

1. In Firebase Console → **Storage** → **Rules**
2. Replace with:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if true;  // Temporary - allows all reads
      allow write: if request.auth != null;  // Only authenticated users can write
    }
  }
}
```
3. Click **Publish**

### Option 3: Using Google Cloud Console (Most Reliable)

1. Go to https://console.cloud.google.com/
2. Select project: **mentorly-66d07**
3. Go to **Cloud Storage** → **Buckets**
4. Click on bucket: **mentorly-66d07.appspot.com**
5. Go to **Permissions** tab
6. Click **Add principal**
7. Add principal: `allUsers`
8. Select role: **Storage Object Viewer**
9. Click **Save**

OR configure CORS:

1. In the same bucket, click the three dots menu
2. Select **Edit CORS configuration**
3. Add:
```json
[
  {
    "origin": ["*"],
    "method": ["GET"],
    "maxAgeSeconds": 3600
  }
]
```

### Option 4: Using gsutil (If installed)

```bash
# Install gsutil first
# For Mac: brew install google-cloud-sdk

# Then run:
gsutil cors set cors.json gs://mentorly-66d07.appspot.com
```

## Verification

After applying any of the above:

1. Wait 1-2 minutes for changes to propagate
2. Hard refresh your browser (Cmd+Shift+R on Mac)
3. Open chat and check if images now display
4. Check browser console (F12) for any CORS errors

## Current Status

✅ **Upload working** - Images are successfully uploaded to Firebase Storage
✅ **Data correct** - Message contains correct `file_type: "image"` and `file_url`
✅ **Code correct** - Image.network widget is implemented properly
❌ **Display failing** - CORS blocking image load from firebasestorage.googleapis.com

## What the Debug Logs Show

```
📸 File type: image
🔗 File URL: https://firebasestorage.googleapis.com/v0/b/mentorly-66d07.firebasestorage.app/o/chat_files%2F...
```

This confirms the URL is stored correctly in Firebase RTDB.

## After Fixing

Once CORS is configured:
- Images will display inline in chat bubbles
- No code changes needed
- App will work immediately

## Security Note

The `"origin": ["*"]` allows all domains. For production, restrict to your domains:
```json
[
  {
    "origin": [
      "https://mentorly-66d07.web.app",
      "https://mentorly-66d07.firebaseapp.com",
      "http://localhost:57101"
    ],
    "method": ["GET"],
    "maxAgeSeconds": 3600
  }
]
```
