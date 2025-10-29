import 'dart:io';
import 'dart:convert';  // 新增：用于 Base64 解码
import 'package:archive/archive_io.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

void main() async {
  final String folderPath = 'C:/Users/Administrator/Desktop/Asm';  // 要加密的文件夹路径（替换为实际路径）
  final String apkPath = 'C:/Users/Administrator/Desktop/test.apk';  // 输出 APK 文件路径
  final String restorePath = 'C:/Users/Administrator/Desktop/restore';  // 恢复文件夹路径（替换为实际路径）
  final String keyString = '7knPktuNWIx9HjmC0ay3pOiYBnl79+Sa4kvHcIrBiwI=';  // 你的 Base64 编码密钥

  // 加密并重命名
  await encryptFolderToApk(folderPath, apkPath, keyString);
  print('加密完成：$apkPath');

  // 恢复
  await decryptApkToFolder(apkPath, restorePath, keyString);
  print('恢复完成：$restorePath');
}

/// 加密文件夹到 APK
Future<void> encryptFolderToApk(String sourceFolder, String outputApk, String keyString) async {
  // 修改：从 Base64 解码密钥为字节
  final keyBytes = base64Decode(keyString);
  final key = encrypt.Key(keyBytes);

  final iv = encrypt.IV.fromSecureRandom(16);  // 随机 IV
  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

  // 步骤1: 压缩文件夹到 ZIP 字节
  final zipBytes = await compressFolderToZipBytes(sourceFolder);

  // 步骤2: 加密 ZIP 字节
  final encrypted = encrypter.encryptBytes(zipBytes, iv: iv);

  // 步骤3: 组合 IV 和加密数据（Base64 格式）
  final ivBase64 = iv.base64;
  final encryptedBase64 = encrypted.base64;
  final combined = '$ivBase64:$encryptedBase64';
  final combinedBytes = combined.codeUnits;  // 转为字节保存

  // 步骤4: 写入临时文件并重命名
  final tempFile = File('temp.enc');
  await tempFile.writeAsBytes(combinedBytes);
  await tempFile.rename(outputApk);
}

/// 解密 APK 到文件夹
Future<void> decryptApkToFolder(String inputApk, String outputFolder, String keyString) async {
  // 修改：从 Base64 解码密钥为字节
  final keyBytes = base64Decode(keyString);
  final key = encrypt.Key(keyBytes);

  final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

  // 步骤1: 读取 APK 文件
  final apkFile = File(inputApk);
  final combinedBytes = await apkFile.readAsBytes();
  final combined = String.fromCharCodes(combinedBytes);
  final parts = combined.split(':');
  if (parts.length != 2) throw Exception('无效的加密文件');

  // 步骤2: 提取 IV 和密文
  final iv = encrypt.IV.fromBase64(parts[0]);
  final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

  // 步骤3: 解密得到 ZIP 字节
  final zipBytes = encrypter.decryptBytes(encrypted, iv: iv);

  // 步骤4: 解压 ZIP 到文件夹
  await decompressZipBytesToFolder(zipBytes, outputFolder);
}

/// 辅助函数：压缩文件夹到 ZIP 字节
Future<List<int>> compressFolderToZipBytes(String sourceFolder) async {
  final archive = Archive();
  final directory = Directory(sourceFolder);
  await for (final entity in directory.list(recursive: true)) {
    if (entity is File) {
      final relativePath = entity.path.replaceFirst(sourceFolder, '').replaceFirst('/', '');
      final fileBytes = await entity.readAsBytes();
      archive.addFile(ArchiveFile(relativePath, fileBytes.length, fileBytes));
    }
  }
  return ZipEncoder().encode(archive)!;
}

/// 辅助函数：解压 ZIP 字节到文件夹
Future<void> decompressZipBytesToFolder(List<int> zipBytes, String outputFolder) async {
  final archive = ZipDecoder().decodeBytes(zipBytes);
  final outputDir = Directory(outputFolder);
  if (!await outputDir.exists()) await outputDir.create(recursive: true);

  for (final file in archive) {
    final filePath = '$outputFolder/${file.name}';
    if (file.isFile) {
      final outFile = File(filePath);
      await outFile.create(recursive: true);
      await outFile.writeAsBytes(file.content as List<int>);
    } else {
      await Directory(filePath).create(recursive: true);
    }
  }
}

----------------------------------------------------
dart create my_encrypter
dart pub get
dart run main.dart



name: my_encrypter
description: A sample command-line application.
version: 1.0.0
# repository: https://github.com/my_org/my_repo

environment:
  sdk: ^3.9.2

# Add regular dependencies here.
dependencies:
  path: ^1.9.0
  archive: ^3.6.1  # 用于 ZIP
  encrypt: ^5.0.3  # 用于 AES

dev_dependencies:
  lints: ^6.0.0
  test: ^1.25.6




