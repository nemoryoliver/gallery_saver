const List<String> videoFormats = [
  '.mp4',
  '.mov',
  '.avi',
  '.wmv',
  '.3gp',
  '.mkv',
  '.flv'
];
const List<String> imageFormats = [
  '.jpeg',
  '.png',
  '.jpg',
  '.gif',
  '.webp',
  '.tif',
  '.heic'
];

const http = 'http';

bool isLocalFilePath(String path) {
  Uri uri = Uri.parse(path);
  return !uri.scheme.contains(http);
}

bool isVideo(String path) {
  for (var f in videoFormats) {
    if (path.toLowerCase().contains(f)) {
      return true;
    }
  }
  return false;
}

bool isImage(String path) {
  for (var f in imageFormats) {
    if (path.toLowerCase().contains(f)) {
      return true;
    }
  }
  return false;
}
