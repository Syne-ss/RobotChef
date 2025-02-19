import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

class YuvChannelling {
  static const MethodChannel platform =
      const MethodChannel("com.example.robot_chef/yuv");

  ///  Transform given image to JPEG compressed through native code.
  ///
  ///  Function gets [CameraImage] in YUV format for processing and returns
  ///  [Uint8List] of JPEG bytes.
  ///
  Future<Uint8List> yuvTransform(CameraImage image) async {
    List<int> strides = new Int32List(image.planes.length * 2);
    int index = 0;
    // We need to transform the image to Uint8List so that the native code could
    // transform it to byte[]
    List<Uint8List> data = image.planes.map((plane) {
      strides[index] = (plane.bytesPerRow);
      index++;
      strides[index] = (plane.bytesPerPixel);
      index++;
      return plane.bytes;
    }).toList();
    Uint8List imageJpeg = await platform.invokeMethod("yuv_transform", {
      'platforms': data,
      'height': image.height,
      'width': image.width,
      'strides': strides
    });

    return imageJpeg;
  }
}
