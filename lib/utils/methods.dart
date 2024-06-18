String changeFileExtensionToMp3(String filePath) {
  // Extract the directory and file name from the file path
  String directory = filePath.substring(0, filePath.lastIndexOf('/'));
  String fileName = filePath.substring(filePath.lastIndexOf('/') + 1);

  // Change the file extension to .mp3
  String newFileName = fileName.replaceAll(RegExp(r'\.[^\.]+$'), '.mp3');

  // Return the new file path
  return '$directory/$newFileName';
}
