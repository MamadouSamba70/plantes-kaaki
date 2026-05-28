import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/scan.dart';
import '../core/services/scan_service.dart';

class ScanProvider extends ChangeNotifier {
  final ScanService _scanService = ScanService();
  final ImagePicker _imagePicker = ImagePicker();

  File? _selectedImage;
  ScanModel? _lastResult;
  List<ScanModel> _history = [];
  
  bool _isScanning = false;
  bool _isLoadingHistory = false;
  String? _errorMessage;

  // Getters
  File? get selectedImage => _selectedImage;
  ScanModel? get lastResult => _lastResult;
  List<ScanModel> get history => _history;
  bool get isScanning => _isScanning;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get errorMessage => _errorMessage;

  // Select image from camera or gallery
  Future<bool> pickImage(ImageSource source) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1080,
      );

      if (pickedFile != null) {
        _selectedImage = File(pickedFile.path);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = "Impossible de sélectionner l'image: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }

  // Clear selected image
  void clearImage() {
    _selectedImage = null;
    _lastResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Trigger diagnostic scan
  Future<ScanModel?> scanLeaf(String userId) async {
    if (_selectedImage == null) {
      _errorMessage = "Veuillez d'abord sélectionner ou prendre une photo.";
      notifyListeners();
      return null;
    }

    _isScanning = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _scanService.performDiagnostic(_selectedImage!, userId);
      _lastResult = result;
      
      // Update history list immediately in-memory by inserting at the start
      _history.insert(0, result);
      
      return result;
    } catch (e) {
      _errorMessage = "Erreur lors de l'analyse : ${e.toString()}";
      return null;
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  // Fetch scan history
  Future<void> fetchHistory(String userId) async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      _history = await _scanService.getUserScans(userId);
    } catch (e) {
      _errorMessage = "Erreur lors du chargement de l'historique : ${e.toString()}";
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  // Set mock result for viewing past diagnostic details
  void setMockResult(ScanModel scanResult) {
    _lastResult = scanResult;
    if (scanResult.imageUrl.isNotEmpty && !scanResult.imageUrl.startsWith('http')) {
      _selectedImage = File(scanResult.imageUrl);
    } else {
      _selectedImage = null;
    }
    notifyListeners();
  }

  // Delete a scan from history
  Future<bool> deleteScan(String scanId, String userId) async {
    try {
      await _scanService.deleteScan(scanId);
      _history.removeWhere((scan) => scan.id == scanId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Fetch global history (for experts)
  Future<void> fetchGlobalHistory() async {
    _isLoadingHistory = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _history = await _scanService.getAllScans();
    } catch (e) {
      _errorMessage = "Erreur de chargement global : ${e.toString()}";
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }
}
