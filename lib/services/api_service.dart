import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/site_list_response.dart';
import '../models/site_user_response.dart';
import '../models/category_response.dart';
import '../models/qc_category_response.dart';
import '../models/qc_point_response.dart';
import '../models/site_album_response.dart';
import '../models/user_detail_response.dart';
import '../models/attendance_response.dart';
import '../models/attendance_check_model.dart';
import '../models/manpower_response.dart';
import '../models/tag_response.dart';
import '../models/task_response.dart';
import '../models/task_detail_model.dart';
import '../models/unit_model.dart';
import '../models/site_agency_model.dart';
import '../models/site_vendor_model.dart';
import '../models/material_category_model.dart';
import '../models/material_model.dart';
import '../models/po_model.dart';
import '../models/grn_detail_model.dart';
import '../models/po_detail_model.dart';
import '../models/billing_address_model.dart';
import '../models/terms_and_condition_model.dart';
import '../models/meeting_model.dart';
import '../models/material_stock_model.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';

class ApiService {
  static const String baseUrl = 'https://pmcprojects.in';
  static const Duration timeout = Duration(seconds: 30);

  // Generic method to handle API responses
  static Future<ApiResponse<T>> handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) async {
    try {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      
      return ApiResponse.fromJson(jsonData, fromJson);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Invalid response format',
      );
    }
  }

  // Generic method to handle HTTP errors
  static String getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'Access denied. You don\'t have permission.';
      case 404:
        return 'Resource not found.';
      case 422:
        return 'Validation error. Please check your input.';
      case 500:
        return 'Internal server error. Please try again later.';
      case 502:
        return 'Bad gateway. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      case 504:
        return 'Gateway timeout. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  static String _parseApiErrorMessage(String responseBody, int statusCode) {
    try {
      final Map<String, dynamic> errorData = json.decode(responseBody);
      if (errorData['message'] != null) {
        return errorData['message'].toString();
      }
    } catch (e) {
      // If parsing fails, use the status code message
    }
    return getErrorMessage(statusCode);
  }

  // Check if response indicates session expiration
  static bool _isSessionExpiredResponse(http.Response response) {
    return response.statusCode == 401 || 
           (response.statusCode == 200 && 
            response.body.toLowerCase().contains('session expired'));
  }

  // Login API
  static Future<LoginResponse> login({
    required String mobile,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/user/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'mobile': mobile,
              'password': password,
            }),
          )
          .timeout(timeout);


      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final loginResponse = LoginResponse.fromJson(jsonData);
        return loginResponse;
      } else {
        return LoginResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return LoginResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
        );
      }
      return LoginResponse(
        status: 0,
        message: 'Something went wrong. $e',
      );
    }
  }

  // Generic GET request
  static Future<ApiResponse<T>> get<T>(
    String endpoint,
    T Function(Map<String, dynamic>)? fromJson,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);

      // Check for session expiration
      if (_isSessionExpiredResponse(response)) {
        return ApiResponse(
          status: 401,
          message: 'Session expired. Please login again.',
        );
      }

      return await handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Network error. Please try again.',
      );
    }
  }

  // Generic POST request
  static Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>)? fromJson,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(data),
          )
          .timeout(timeout);

      // Check for session expiration
      if (_isSessionExpiredResponse(response)) {
        return ApiResponse(
          status: 401,
          message: 'Session expired. Please login again.',
        );
      }

      return await handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Network error. Please try again.',
      );
    }
  }

  // Generic PUT request
  static Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>)? fromJson,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(data),
          )
          .timeout(timeout);

      return await handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Network error. Please try again.',
      );
    }
  }

  // Generic DELETE request
  static Future<ApiResponse<T>> delete<T>(
    String endpoint,
    T Function(Map<String, dynamic>)? fromJson,
  ) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);

      return await handleResponse(response, fromJson);
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Network error. Please try again.',
      );
    }
  }

  // Get Site List API
  static Future<SiteListResponse> getSiteList({
    required String apiToken,
    String status = '',
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
      };

      // Add status filter if provided
      if (status.isNotEmpty) {
        requestData['status'] = status;
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/getSiteList'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestData,
          )
          .timeout(timeout);


      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final siteListResponse = SiteListResponse.fromJson(jsonData);
        
        // Check for session expiration in response message
        if (SessionManager.isSessionExpired(siteListResponse.message)) {
          return SiteListResponse(
            status: 401,
            message: 'Session expired. Please login again.',
            data: [],
          );
        }
        
        return siteListResponse;
      } else {
        return SiteListResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          data: [],
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return SiteListResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
          data: [],
        );
      }
      return SiteListResponse(
        status: 0,
        message: 'Something went wrong. $e',
        data: [],
      );
    }
  }

  // Get Users by Site API
  static Future<SiteUserResponse> getUsersBySite({
    required String apiToken,
    required int siteId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'site_id': siteId.toString(),
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/getUserBySite'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestData,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final siteUserResponse = SiteUserResponse.fromJson(jsonData);
        return siteUserResponse;
      } else {
        return SiteUserResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          users: [],
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return SiteUserResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
          users: [],
        );
      }
      return SiteUserResponse(
        status: 0,
        message: 'Something went wrong. $e',
        users: [],
      );
    }
  }

  // Update Site API
  static Future<ApiResponse> updateSite({
    required String apiToken,
    required int siteId,
    String? siteName,
    String? clientName,
    String? architectName,
    String? address,
    double? latitude,
    double? longitude,
    String? startDate,
    String? endDate,
    int? minRange,
    int? maxRange,
    List<File>? images,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'site_id': siteId.toString(),
      };

      // Add optional fields if provided
      if (siteName != null && siteName.isNotEmpty) {
        requestData['name'] = siteName;
      }
      if (clientName != null && clientName.isNotEmpty) {
        requestData['client_name'] = clientName;
      }
      if (architectName != null && architectName.isNotEmpty) {
        requestData['architect_name'] = architectName;
      }
      if (address != null && address.isNotEmpty) {
        requestData['address'] = address;
      }
      if (latitude != null) {
        requestData['latitude'] = latitude.toString();
      }
      if (longitude != null) {
        requestData['longitude'] = longitude.toString();
      }
      if (startDate != null && startDate.isNotEmpty) {
        requestData['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        requestData['end_date'] = endDate;
      }
      if (minRange != null) {
        requestData['min_range'] = minRange.toString();
      }
      if (maxRange != null) {
        requestData['max_range'] = maxRange.toString();
      }

      http.Response response;
      
      if (images != null && images.isNotEmpty) {
        // Use multipart request for image uploads
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/api/updateSite'),
        );
        
        // Add text fields
        request.fields.addAll(Map<String, String>.from(requestData));
        
        // Add image files
        for (int i = 0; i < images.length; i++) {
          final file = images[i];
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();
          final multipartFile = http.MultipartFile(
            'images[]',
            stream,
            length,
            filename: file.path.split('/').last,
          );
          request.files.add(multipartFile);
        }
        
        final streamedResponse = await request.send().timeout(timeout);
        final responseBody = await streamedResponse.stream.bytesToString();
        response = http.Response(responseBody, streamedResponse.statusCode);
      } else {
        // Use regular POST request for text-only updates
        response = await http
            .post(
              Uri.parse('$baseUrl/api/updateSite'),
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Accept': 'application/json',
              },
              body: requestData,
            )
            .timeout(timeout);
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return ApiResponse.fromJson(jsonData, null);
      } else {
        return ApiResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          data: null,
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return ApiResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
          data: null,
        );
      }
      return ApiResponse(
        status: 0,
        message: 'Something went wrong. $e',
        data: null,
      );
    }
  }

  // Get All Users API
  static Future<SiteUserResponse> getAllUsers({
    required String apiToken,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/getAllUser'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestData,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final siteUserResponse = SiteUserResponse.fromJson(jsonData);
        return siteUserResponse;
      } else {
        return SiteUserResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          users: [],
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return SiteUserResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
          users: [],
        );
      }
      return SiteUserResponse(
        status: 0,
        message: 'Something went wrong. $e',
        users: [],
      );
    }
  }

  // Get Site List By User API
  static Future<SiteListResponse> getSiteListByUser({
    required String apiToken,
    required int userId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'user_id': userId.toString(),
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/getSiteListByUser'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestData,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final siteListResponse = SiteListResponse.fromJson(jsonData);
        
        // Check for session expiration in response message
        if (SessionManager.isSessionExpired(siteListResponse.message)) {
          return SiteListResponse(
            status: 401,
            message: 'Session expired. Please login again.',
            data: [],
          );
        }
        
        return siteListResponse;
      } else {
        return SiteListResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          data: [],
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return SiteListResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
          data: [],
        );
      }
      return SiteListResponse(
        status: 0,
        message: 'Something went wrong. $e',
        data: [],
      );
    }
  }

  // Pin/Unpin Site API
  static Future<Map<String, dynamic>> pinSite({
    required String apiToken,
    required int siteId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/pinSite'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: {
              'api_token': apiToken,
              'site_id': siteId.toString(),
            },
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return {
          'success': jsonData['status'] == 1,
          'message': jsonData['message'] ?? 'Operation completed',
        };
      }
      return {
        'success': false,
        'message': 'Failed to pin/unpin site',
      };
    } catch (e) {
      debugPrint('Error pinning/unpinning site: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }

  static Future<SiteAlbumResponse> getSiteAlbumList(int siteId) async {
    try {
      final token = AuthService.currentToken;
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/v2/getSiteAlbumList'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'site_id': siteId.toString(),
          'api_token': token,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return SiteAlbumResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to load site album list: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching site album list: $e');
    }
  }

  // Save Site Sub Album API
  static Future<ApiResponse<Map<String, dynamic>>> saveSiteSubAlbum({
    required int siteId,
    required int parentId,
    required String albumName,
  }) async {
    try {
      final token = AuthService.currentToken;
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/v2/saveSiteSubAlbum'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'site_id': siteId.toString(),
          'api_token': token,
          'parent_id': parentId.toString(),
          'album_name': albumName,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return ApiResponse.fromJson(jsonResponse, null);
      } else {
        return ApiResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return ApiResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
        );
      }
      return ApiResponse(
        status: 0,
        message: 'Something went wrong. $e',
      );
    }
  }

  // Edit Site Album API (rename folder)
  static Future<ApiResponse<Map<String, dynamic>>> editSiteAlbum({
    required int albumId,
    required String albumName,
  }) async {
    try {
      final token = AuthService.currentToken;
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/v2/editSiteAlbum'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'api_token': token,
          'album_id': albumId.toString(),
          'album_name': albumName,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return ApiResponse.fromJson(jsonResponse, null);
      } else {
        return ApiResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return ApiResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
        );
      }
      return ApiResponse(
        status: 0,
        message: 'Something went wrong. $e',
      );
    }
  }

  // Delete Site Album API
  static Future<ApiResponse<Map<String, dynamic>>> deleteSiteAlbum({
    required int albumId,
  }) async {
    try {
      final token = AuthService.currentToken;
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/v2/deleteSiteAlbum'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'api_token': token,
          'album_id': albumId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return ApiResponse.fromJson(jsonResponse, null);
      } else {
        return ApiResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return ApiResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
        );
      }
      return ApiResponse(
        status: 0,
        message: 'Something went wrong. $e',
      );
    }
  }

  // Save Image API
  static Future<ApiResponse<Map<String, dynamic>>> saveImage({
    required int subAlbumId,
    required List<File> images,
  }) async {
    try {
      final token = AuthService.currentToken;
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v2/saveImage'),
      );

      // Add headers
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add form fields
      request.fields['api_token'] = token;
      request.fields['sub_album_id'] = subAlbumId.toString();

      // Add image files
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();
        
        final multipartFile = http.MultipartFile(
          'images[]',
          stream,
          length,
          filename: file.path.split('/').last,
        );
        
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return ApiResponse.fromJson(jsonResponse, null);
      } else {
        return ApiResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return ApiResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
        );
      }
      return ApiResponse(
        status: 0,
        message: 'Something went wrong. $e',
      );
    }
  }

  // Save Attachment API
  static Future<ApiResponse<Map<String, dynamic>>> saveAttachment({
    required int subAlbumId,
    required List<File> attachments,
  }) async {
    try {
      final token = AuthService.currentToken;
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v2/saveAttachment'),
      );

      // Add headers
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add form fields
      request.fields['api_token'] = token;
      request.fields['sub_album_id'] = subAlbumId.toString();

      // Add attachment files
      for (int i = 0; i < attachments.length; i++) {
        final file = attachments[i];
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();
        
        final multipartFile = http.MultipartFile(
          'attachments[]',
          stream,
          length,
          filename: file.path.split('/').last,
        );
        
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return ApiResponse.fromJson(jsonResponse, null);
      } else {
        return ApiResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return ApiResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
        );
      }
      return ApiResponse(
        status: 0,
        message: 'Something went wrong. $e',
      );
    }
  }

  // Get User Details by ID API
  static Future<UserDetailResponse> getUserFromId({
    required String apiToken,
    required int userId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/getUserFromId'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'api_token': apiToken,
              'user_id': userId,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return UserDetailResponse.fromJson(jsonData);
      } else {
        return UserDetailResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return UserDetailResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
        );
      }
      return UserDetailResponse(
        status: 0,
        message: 'Something went wrong. $e',
      );
    }
  }

  // Attendance Check API
  static Future<AttendanceCheckModel?> attendanceCheck({
    required String apiToken,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/attendanceCheck'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return AttendanceCheckModel.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Save Attendance API
  static Future<bool> saveAttendance({
    required String type,
    required String siteId,
    required String address,
    required String remark,
    required String latitude,
    required String longitude,
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return false;
      }

      final Map<String, dynamic> requestData = {
        'api_token': token,
        'type': type,
        'site_id': siteId,
        'address': address,
        'remark': remark,
        'latitude': latitude,
        'longitude': longitude,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/saveAttendance'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);


      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final success = jsonData['status'] == 1 || jsonData['success'] == true;
        if (!success) {

        }
        return success;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Get Site Vendors API
  static Future<SiteAgencyResponse?> getSiteAgency({
    required int siteId,
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return SiteAgencyResponse(
          status: 'error',
          message: 'Authentication token not found. Please login again.',
          data: [],
        );
      }

      final Map<String, dynamic> requestData = {
        'api_token': token,
        'site_id': siteId.toString(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/getAgency'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return SiteAgencyResponse.fromJson(jsonData);
      } else {
        return SiteAgencyResponse(
          status: 'error',
          message: _parseApiErrorMessage(response.body, response.statusCode),
          data: [],
        );
      }
    } catch (e) {
      return SiteAgencyResponse(
        status: 'error',
        message: 'Network error. Please check your connection and try again.',
        data: [],
      );
    }
  }

  // Save Site Agency API
  static Future<Map<String, dynamic>?> saveSiteAgency({
    required int siteId,
    required int categoryId,
    required String name,
    required String mobile,
    required String email,
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return {
          'status': 'error',
          'message': 'Authentication token not found. Please login again.',
          'data': null,
        };
      }

      final Map<String, dynamic> requestData = {
        'api_token': token,
        'site_id': siteId.toString(),
        'category_id': categoryId.toString(),
        'name': name,
        'mobile': mobile,
        'email': email,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/saveAgency'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData; // Return the full response
      } else {
        return {
          'status': 'error',
          'message': _parseApiErrorMessage(response.body, response.statusCode),
          'data': null,
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error. Please check your connection and try again.',
        'data': null,
      };
    }
  }

  // Update Site Agency API
  static Future<Map<String, dynamic>?> updateSiteAgency({
    required int agencyId,
    required int siteId,
    required int categoryId,
    required String name,
    required String mobile,
    required String email,
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return {
          'status': 'error',
          'message': 'Authentication token not found. Please login again.',
          'data': null,
        };
      }

      final Map<String, dynamic> requestData = {
        'api_token': token,
        'vender_id': agencyId.toString(), // Changed from 'id' to 'vender_id' to match API
        'site_id': siteId.toString(),
        'category_id': categoryId.toString(),
        'name': name,
        'mobile': mobile,
        'email': email,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/updateAgency'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData; // Return the full response
      } else {
        return {
          'status': 'error',
          'message': _parseApiErrorMessage(response.body, response.statusCode),
          'data': null,
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error. Please check your connection and try again.',
        'data': null,
      };
    }
  }

  // Delete Site Agency API
  static Future<Map<String, dynamic>?> deleteSiteAgency({
    required int agencyId,
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return {
          'status': 'error',
          'message': 'Authentication token not found. Please login again.',
          'success': false,
        };
      }

      final Map<String, dynamic> requestData = {
        'api_token': token,
        'vender_id': agencyId.toString(), // Changed from 'id' to 'vender_id' to match API
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/deleteAgency'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);


      log("Delete agency response == ${response.statusCode}");
      log("Delete agency response == ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData; // Return the full response
      } else {
        return {
          'status': 'error',
          'message': _parseApiErrorMessage(response.body, response.statusCode),
          'success': false,
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error. Please check your connection and try again.',
        'success': false,
      };
    }
  }

  // Get Attendance Report API
  static Future<AttendanceResponse> getAttendanceReport({
    required String apiToken,
    required int userId,
    required String startDate,
    required String endDate,
    int page = 1,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'user_id': userId.toString(),
        'start_date': startDate,
        'end_date': endDate,
        'page': page.toString(),
      };


      final response = await http
          .post(
            Uri.parse('$baseUrl/api/attendanceReport'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestData,
          )
          .timeout(timeout);


      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final attendanceResponse = AttendanceResponse.fromJson(jsonData);

        return attendanceResponse;
      } else {
        return AttendanceResponse(
          status: 0,
          data: [],
          total: 0,
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return AttendanceResponse(
          status: 0,
          data: [],
          total: 0,
        );
      }
      return AttendanceResponse(
        status: 0,
        data: [],
        total: 0,
      );
    }
  }

  // Assign Site to User API
  static Future<SiteUserResponse> assignSite({
    required String apiToken,
    required int userId,
    required int siteId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'user_id': userId.toString(),
        'site_id': siteId.toString(),
      };


      final response = await http
          .post(
            Uri.parse('$baseUrl/api/assignSite'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestData,
          )
          .timeout(timeout);


      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return SiteUserResponse.fromJson(jsonData);
      } else {
        return SiteUserResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          users: [],
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return SiteUserResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
          users: [],
        );
      }
      return SiteUserResponse(
        status: 0,
        message: 'Something went wrong. $e',
        users: [],
      );
    }
  }

  // Remove User from Site API
  static Future<SiteUserResponse> removeUserFromSite({
    required String apiToken,
    required int userId,
    required int siteId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'user_id': userId.toString(),
        'site_id': siteId.toString(),
      };


      final response = await http
          .post(
            Uri.parse('$baseUrl/api/removeUserFromSite'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestData,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return SiteUserResponse.fromJson(jsonData);
      } else {
        return SiteUserResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          users: [],
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return SiteUserResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
          users: [],
        );
      }
      return SiteUserResponse(
        status: 0,
        message: 'Something went wrong. $e',
        users: [],
      );
    }
  }

  // Get Categories by Site ID API
  static Future<CategoryResponse> getCategoriesBySite({
    required String apiToken,
    required int siteId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'site_id': siteId.toString(),
      };


      final response = await http
          .post(
            Uri.parse('$baseUrl/api/getCategoryBySiteId'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
          )
          .timeout(timeout);


      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return CategoryResponse.fromJson(jsonData);
      } else {
        return CategoryResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          categories: [],
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return CategoryResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
          categories: [],
        );
      }
      return CategoryResponse(
        status: 0,
        message: 'Something went wrong. $e',
        categories: [],
      );
    }
  }

  // Create Category API
  static Future<CategoryResponse> createCategory({
    required String apiToken,
    required int siteId,
    required String name,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'site_id': siteId.toString(),
        'name': name,
        'cat_sub_id': 5,
      };


      final response = await http
          .post(
            Uri.parse('$baseUrl/api/createCategory'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
          )
          .timeout(timeout);


      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return CategoryResponse.fromJson(jsonData);
      } else {
        return CategoryResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          categories: [],
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return CategoryResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
          categories: [],
        );
      }
      return CategoryResponse(
        status: 0,
        message: 'Something went wrong. $e',
        categories: [],
      );
    }
  }

  // Update Category API
  static Future<CategoryResponse> updateCategory({
    required String apiToken,
    required int categoryId,
    required String name,
    required int siteId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'category_id': categoryId.toString(),
        'name': name,
        'site_id': siteId.toString(),
        'cat_sub_id': '5',
      };


      final response = await http
          .post(
            Uri.parse('$baseUrl/api/editCategory'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
          )
          .timeout(timeout);


      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return CategoryResponse.fromJson(jsonData);
      } else {
        return CategoryResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          categories: [],
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return CategoryResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
          categories: [],
        );
      }
      return CategoryResponse(
        status: 0,
        message: 'Something went wrong. $e',
        categories: [],
      );
    }
  }

  // Delete Category API
  static Future<CategoryResponse> deleteCategory({
    required String apiToken,
    required int categoryId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'category_id': categoryId.toString(),
      };


      final response = await http
          .post(
            Uri.parse('$baseUrl/api/deleteCategory'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
          )
          .timeout(timeout);


      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return CategoryResponse.fromJson(jsonData);
      } else {
        return CategoryResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          categories: [],
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return CategoryResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
          categories: [],
        );
      }
      return CategoryResponse(
        status: 0,
        message: 'Something went wrong. $e',
        categories: [],
      );
    }
  }

  // Get Manpower API
  static Future<ManpowerResponse> getManpower({
    required String apiToken,
    required int siteId,
    required String date,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'site_id': siteId.toString(),
        'date': date,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/getMenPower'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return ManpowerResponse.fromJson(jsonData);
      } else {
        return ManpowerResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          data: [],
          whatsAppMessage: '',
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return ManpowerResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
          data: [],
          whatsAppMessage: '',
        );
      }
      return ManpowerResponse(
        status: 0,
        message: 'Something went wrong. $e',
        data: [],
        whatsAppMessage: '',
      );
    }
  }

  // Save Manpower API
  static Future<ManpowerResponse> saveManpower({
    required String apiToken,
    required int siteId,
    required String date,
    required List<Map<String, dynamic>> data,
  }) async {
    try {
      // Convert data to the format expected by the server
      final List<Map<String, dynamic>> formattedData = data.map((entry) => {
        'category_id': entry['category_id'],
        'shift': entry['shift'],
        'skilled_worker': entry['skilled_worker'],
        'unskilled_worker': entry['unskilled_worker'],
      }).toList();

      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'site_id': siteId.toString(),
        'date': date,
        'data': formattedData,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/saveManPower'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(requestData),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return ManpowerResponse.fromJson(jsonData);
      } else {
        return ManpowerResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          data: [],
          whatsAppMessage: '',
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return ManpowerResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
          data: [],
          whatsAppMessage: '',
        );
      }
      return ManpowerResponse(
        status: 0,
        message: 'Something went wrong. $e',
        data: [],
        whatsAppMessage: '',
      );
    }
  }

  // Get QC Categories API
  static Future<QcCategoryResponse> getQcCategories({
    required String apiToken,
    int page = 1,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'page': page.toString(),
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/quality/getQualityCheckCategory'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return QcCategoryResponse.fromJson(jsonData);
      } else {
        return QcCategoryResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          points: [],
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return QcCategoryResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
          points: [],
        );
      }
      return QcCategoryResponse(
        status: 0,
        message: 'Something went wrong. $e',
        points: [],
      );
    }
  }

  // Create QC Category API
  static Future<QcCategoryResponse> createQcCategory({
    required String apiToken,
    required String name,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'name': name,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/quality/createQCCategory'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return QcCategoryResponse.fromJson(jsonData);
      } else {
        return QcCategoryResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          points: [],
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return QcCategoryResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
          points: [],
        );
      }
      return QcCategoryResponse(
        status: 0,
        message: 'Something went wrong. $e',
        points: [],
      );
    }
  }

  // Get QC Points API
  static Future<QcPointResponse> getQcPoints({
    required String apiToken,
    required String type,
    required int categoryId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'type': type,
        'category_id': categoryId.toString(),
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/quality/getQualityPoint'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return QcPointResponse.fromJson(jsonData);
      } else {
        return QcPointResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          points: [],
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return QcPointResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
          points: [],
        );
      }
      return QcPointResponse(
        status: 0,
        message: 'Something went wrong. $e',
        points: [],
      );
    }
  }

  // Update QC Point API
  static Future<QcPointResponse> updateQcPoint({
    required String apiToken,
    required String type,
    required String point,
    required int pointId,
    required int categoryId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'type': type,
        'point': point,
        'point_id': pointId.toString(),
        'category_id': categoryId.toString(),
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/quality/updateQualityPoint'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return QcPointResponse.fromJson(jsonData);
      } else {
        return QcPointResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          points: [],
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return QcPointResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
          points: [],
        );
      }
      return QcPointResponse(
        status: 0,
        message: 'Something went wrong. $e',
        points: [],
      );
    }
  }

  // Delete QC Point API
  static Future<QcPointResponse> deleteQcPoint({
    required String apiToken,
    required int pointId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'point_id': pointId.toString(),
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/quality/deleteQualityPoint'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return QcPointResponse.fromJson(jsonData);
      } else {
        return QcPointResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          points: [],
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return QcPointResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
          points: [],
        );
      }
      return QcPointResponse(
        status: 0,
        message: 'Something went wrong. $e',
        points: [],
      );
    }
  }

  // Store QC Point API
  static Future<QcPointResponse> storeQcPoint({
    required String apiToken,
    required String type,
    required String point,
    required int categoryId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'type': type,
        'point': point,
        'category_id': categoryId.toString(),
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/quality/storeQualityPoint'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return QcPointResponse.fromJson(jsonData);
      } else {
        return QcPointResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          points: [],
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return QcPointResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
          points: [],
        );
      }
      return QcPointResponse(
        status: 0,
        message: 'Something went wrong. $e',
        points: [],
      );
    }
  }

  // Create Site API
  static Future<ApiResponse<dynamic>> createSite({
    required String apiToken,
    required String siteName,
    required String clientName,
    required String architectName,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> images,
    required double latitude,
    required double longitude,
    required String address,
    required int minRange,
    required int maxRange,
  }) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/createSite'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
      });

      // Add text fields
      request.fields.addAll({
        'api_token': apiToken,
        'name': siteName,
        'client_name': clientName,
        'architect_name': architectName,
        'start_date': startDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
        'end_date': endDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'address': address,
        'min_range': minRange.toString(),
        'max_range': maxRange.toString(),
        'company': "Core PMC",
      });

      // Add image files
      for (int i = 0; i < images.length; i++) {
        final file = File(images[i]);
        if (await file.exists()) {
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();
          final multipartFile = http.MultipartFile(
            'images[]',
            stream,
            length,
            filename: file.path.split('/').last,
          );
          request.files.add(multipartFile);
        }
      }

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (_isSessionExpiredResponse(response)) {
        return ApiResponse(
          status: 401,
          message: 'Session expired',
        );
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return ApiResponse.fromJson(jsonData, null);
      } else {
        return ApiResponse(
          status: response.statusCode,
          message: getErrorMessage(response.statusCode),
        );
      }
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Failed to create site: $e',
      );
    }
  }

  // Get Tags API
  static Future<TagResponse> getTags({
    required String apiToken,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/getTags'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return TagResponse.fromJson(jsonData);
      } else {
        return TagResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          data: [],
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return TagResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
          data: [],
        );
      }
      return TagResponse(
        status: 0,
        message: 'Something went wrong. $e',
        data: [],
      );
    }
  }

  // Get Task List API
  static Future<TaskResponse> getTaskList({
    required String apiToken,
    required int siteId,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'site_id': siteId,
      };

      // Add filters if provided
      if (filters != null) {
        requestData.addAll(filters);
      }

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/getTaskList'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        return TaskResponse.fromJson(jsonData);
      } else {

        return TaskResponse(
          status: 0,
          totalTasks: 0,
          data: [],
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return TaskResponse(
          status: 0,
          totalTasks: 0,
          data: [],
        );
      }
      return TaskResponse(
        status: 0,
        totalTasks: 0,
        data: [],
      );
    }
  }

  // Get Task Detail API
  static Future<TaskDetailModel> getTaskDetail({
    required String apiToken,
    required int taskId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'task_id': taskId,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/getTaskDetail'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['status'] == 1 && jsonData['data'] != null) {
          return TaskDetailModel.fromJson(jsonData['data']);
        } else {
          throw Exception('Failed to load task details');
        }
      } else {
        throw Exception('Failed to load task details');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        throw Exception('No internet connection. Please check your network.');
      }
      throw Exception('Failed to load task details: $e');
    }
  }

  // Edit Task API
  static Future<ApiResponse?> editTask(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/editTask'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: Uri(queryParameters: data.map((key, value) => MapEntry(key, value.toString()))).query,
          )
          .timeout(timeout);



      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return ApiResponse(
          status: jsonData['status'] ?? 0,
          message: jsonData['message'] ?? '',
        );
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Get Units API
  static Future<UnitResponse?> getUnits() async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/getUnit'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return UnitResponse.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Delete Task API
  static Future<ApiResponse?> deleteTask({
    required String apiToken,
    required int taskId,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/deleteTask'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: {
              'api_token': apiToken,
              'task_id': taskId.toString(),
            },
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return ApiResponse(
          status: jsonData['status'] ?? 0,
          message: jsonData['message'] ?? '',
        );
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Delete Task Image API
  static Future<ApiResponse?> deleteTaskImage({
    required String apiToken,
    required int imageId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'image_id': imageId,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/delete_task_image'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return ApiResponse(
          status: jsonData['status'] ?? 0,
          message: jsonData['message'] ?? '',
        );
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Delete Task Progress Image API
  static Future<ApiResponse?> deleteTaskProgressImage({
    required String apiToken,
    required int imageId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'image_id': imageId,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/delete_task_progress_image'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return ApiResponse(
          status: jsonData['status'] ?? 0,
          message: jsonData['message'] ?? '',
        );
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Delete Album Image API
  static Future<ApiResponse?> deleteAlbumImage({
    required String apiToken,
    required int imageId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'image_id': imageId,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/v2/deleteAlbumImage'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return ApiResponse(
          status: jsonData['status'] ?? 0,
          message: jsonData['message'] ?? '',
        );
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Update Progress API
  static Future<ApiResponse?> updateProgress({
    required String apiToken,
    required int taskId,
    required String workDone,
    required Map<String, dynamic> questionAnswer,
  }) async {
    try {
      // Combine all data into a single map
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'task_id': taskId.toString(),
        'work_done': workDone,
        'question_answer': questionAnswer,
      };

      // Debug: Print the request data

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/updateProgress'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestData),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return ApiResponse(
          status: jsonData['status'] ?? 0,
          message: jsonData['message'] ?? '',
        );
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Update task progress (normal tasks)
  static Future<ApiResponse?> updateTaskProgress({
    required String apiToken,
    required int taskId,
    required String workDone,
    required String workLeft,
    required String skillWorkers,
    required String unskilledWorkers,
    String? remark,
    String? comment,
    String? instruction,
    List<File> images = const [],
    List<Map<String, dynamic>>? usedMaterials,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/updateProgress'),
      );

      // Add text fields
      request.fields['api_token'] = apiToken;
      request.fields['task_id'] = taskId.toString();
      request.fields['work_done'] = workDone;
      request.fields['work_left'] = workLeft;
      request.fields['skill_workers'] = skillWorkers;
      request.fields['unskill_workers'] = unskilledWorkers;

      // Add optional fields
      if (remark != null && remark.isNotEmpty) {
        request.fields['remark'] = remark;
      }
      if (comment != null && comment.isNotEmpty) {
        request.fields['comment'] = comment;
      }
      if (instruction != null && instruction.isNotEmpty) {
        request.fields['instruction'] = instruction;
      }
      
      // Add used materials if provided
      if (usedMaterials != null && usedMaterials.isNotEmpty) {
        request.fields['used_material'] = json.encode(usedMaterials);
      }

      // Add image files
      for (File imageFile in images) {
        final file = await http.MultipartFile.fromPath(
          'images[]',
          imageFile.path,
        );
        request.files.add(file);
      }


      log("Request field == ${request.fields}");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final responseData = json.decode(response.body);
      return ApiResponse.fromJson(responseData, null);
    } catch (e) {
      return null;
    }
  }

  /// Update simple task (decision, drawing, selection, quotation)
  static Future<ApiResponse?> updateSimpleTask({
    required String apiToken,
    required int taskId,
    String? remark,
    List<File> images = const [],
    List<File> attachments = const [],
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/updateProgress'),
      );

      // Add text fields
      request.fields['api_token'] = apiToken;
      request.fields['task_id'] = taskId.toString();

      // Add optional fields
      if (remark != null && remark.isNotEmpty) {
        request.fields['remark'] = remark;
      }

      // Add image files
      for (File imageFile in images) {
        final file = await http.MultipartFile.fromPath(
          'images[]',
          imageFile.path,
        );
        request.files.add(file);
      }

      // Add attachment files
      for (File attachmentFile in attachments) {
        final file = await http.MultipartFile.fromPath(
          'attachments[]',
          attachmentFile.path,
        );
        request.files.add(file);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final responseData = json.decode(response.body);
      return ApiResponse.fromJson(responseData, null);
    } catch (e) {
      return null;
    }
  }

  /// Accept task API
  static Future<ApiResponse?> acceptTask({
    required String apiToken,
    required int taskId,
    required String remark,
    required String completionDate,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/updateProgress'),
      );

      // Add text fields
      request.fields['api_token'] = apiToken;
      request.fields['task_id'] = taskId.toString();
      request.fields['remark'] = remark;
      request.fields['completion_date'] = completionDate;
      request.fields['is_approved'] = '1';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final responseData = json.decode(response.body);
      return ApiResponse.fromJson(responseData, null);
    } catch (e) {
      return null;
    }
  }

  // Get Material Categories API
  static Future<MaterialCategoryResponse?> getMaterialCategories({
    int page = 1,
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return null;
      }

      final Map<String, dynamic> requestData = {
        'api_token': token,
        'page': page.toString(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/material/getMaterialCategory'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);


      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return MaterialCategoryResponse.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Store Material Category API
  static Future<MaterialCategoryCreateResponse?> storeMaterialCategory({
    required String name,
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return null;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/material/storeMaterialCategory'),
      );

      request.fields['api_token'] = token;
      request.fields['name'] = name;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);


      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return MaterialCategoryCreateResponse.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Save Material API
  static Future<MaterialCreateResponse?> saveMaterial({
    required String name,
    required String unitOfMeasurement,
    required String specification,
    required int categoryId,
    required String sku,
    required String unitPrice,
    String? gst,
    String? description,
    String? brandName,
    String? hsn,
    int minStock = 0,
    int availableStock = 0,
    String? length,
    String? width,
    String? height,
    String? weight,
    String? color,
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return null;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/material/saveMaterial'),
      );

      // Add required fields
      request.fields['api_token'] = token;
      request.fields['name'] = name;
      request.fields['unit_of_measurement'] = unitOfMeasurement;
      request.fields['specification'] = specification;
      request.fields['category_id'] = categoryId.toString();
      request.fields['sku'] = sku;
      request.fields['unit_price'] = unitPrice;
      if (gst != null && gst.isNotEmpty) {
        request.fields['gst'] = gst;
      }
      
      if (hsn != null && hsn.isNotEmpty) {
        request.fields['hsn'] = hsn;
      }
      request.fields['min_stock'] = minStock.toString();
      request.fields['available_stock'] = availableStock.toString();
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }
      if (brandName != null && brandName.isNotEmpty) {
        request.fields['brand_name'] = brandName;
      }
      if (length != null && length.isNotEmpty) {
        request.fields['length'] = length;
      }
      if (width != null && width.isNotEmpty) {
        request.fields['width'] = width;
      }
      if (height != null && height.isNotEmpty) {
        request.fields['height'] = height;
      }
      if (weight != null && weight.isNotEmpty) {
        request.fields['weight'] = weight;
      }
      if (color != null && color.isNotEmpty) {
        request.fields['color'] = color;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);


      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return MaterialCreateResponse.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Get Materials API
  static Future<MaterialResponse?> getMaterials({
    int page = 1,
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return null;
      }

      final Map<String, dynamic> requestData = {
        'api_token': token,
        'page': page.toString(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/material/getMaterial'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);



      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return MaterialResponse.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Get Material Stock API
  static Future<MaterialStockModel?> getMaterialStock({
    required int materialId,
    int page = 1,
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return null;
      }

      final Map<String, dynamic> requestData = {
        'api_token': token,
        'material_id': materialId.toString(),
        'page': page.toString(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/material/getmaterialStock'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return MaterialStockModel.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Update Material Stock API (stockIn/stockOut)
  static Future<bool> updateMaterialStock({
    required int materialId,
    required double quantity,
    required String description,
    required bool isStockIn, // true for stockIn, false for stockOut
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return false;
      }

      final Map<String, dynamic> requestData = {
        'api_token': token,
        'material_id': materialId.toString(),
        'quantity': quantity.toString(),
        'description': description,
      };

      final endpoint = isStockIn ? 'stockIn' : 'stockOut';
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/material/$endpoint'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData['status'] == 1;
      } else {
        return false;
      }
    } catch (e) {
      print('Error updating material stock: $e');
      return false;
    }
  }

  // Get PO Orders API
  static Future<ApiResponse<List<POModel>>?> getPOOrders({
    required int siteId,
    int page = 1,
    String search = '',
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return null;
      }

      final Map<String, dynamic> requestData = {
        'api_token': token,
        'page': page.toString(),
        'site_id': siteId.toString(),
        'search': search,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/material/getMaterialPOlist'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        
        if (jsonData['status'] == 1 && jsonData['data'] != null) {
          final List<dynamic> dataList = jsonData['data'];
          final List<POModel> poOrders = dataList.map((item) => POModel.fromJson(item)).toList();
          
          return ApiResponse<List<POModel>>(
            status: jsonData['status'],
            message: jsonData['message'] ?? '',
            data: poOrders,
          );
        } else {
          return ApiResponse<List<POModel>>(
            status: jsonData['status'] ?? 0,
            message: jsonData['message'] ?? 'Failed to load PO orders',
            data: [],
          );
        }
      } else {
        return ApiResponse<List<POModel>>(
          status: 0,
          message: getErrorMessage(response.statusCode),
          data: [],
        );
      }
    } catch (e) {
      return ApiResponse<List<POModel>>(
        status: 0,
        message: 'Network error: ${e.toString()}',
        data: [],
      );
    }
  }

  // Get PO Detail API
  static Future<ApiResponse<PODetailModel>?> getPODetail({
    required int materialPoId,
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return null;
      }

      final Map<String, dynamic> requestData = {
        'api_token': token,
        'material_po_id': materialPoId.toString(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/material/getMaterialPODetail'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        
        if (jsonData['status'] == 1 && jsonData['data'] != null) {
          final PODetailModel poDetail = PODetailModel.fromJson(jsonData['data']);
          
          return ApiResponse<PODetailModel>(
            status: jsonData['status'],
            message: jsonData['message'] ?? '',
            data: poDetail,
          );
        } else {
          return ApiResponse<PODetailModel>(
            status: jsonData['status'] ?? 0,
            message: jsonData['message'] ?? 'Failed to load PO details',
            data: PODetailModel.fromJson({}),
          );
        }
      } else {
        return ApiResponse<PODetailModel>(
          status: 0,
          message: getErrorMessage(response.statusCode),
          data: PODetailModel.fromJson({}),
        );
      }
    } catch (e) {
      return ApiResponse<PODetailModel>(
        status: 0,
        message: 'Network error: ${e.toString()}',
        data: PODetailModel.fromJson({}),
      );
    }
  }

  // Store Payment API
  static Future<ApiResponse<Map<String, dynamic>>?> storePayment({
    required int poId,
    int? grnId,
    required String paymentDate,
    required String paymentAmount,
    required String paymentMode,
    String? remark,
    String? transactionId,
    required String advanceId,
    List<File>? documents,
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return null;
      }

      http.Response response;

      // Use multipart request if documents are provided
      if (documents != null && documents.isNotEmpty) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/api/materialpo/storePayment'),
        );

        // Add form fields
        request.fields['api_token'] = token;
        request.fields['po_id'] = poId.toString();
        request.fields['grn_id'] = grnId?.toString() ?? '';
        request.fields['payment_date'] = paymentDate;
        request.fields['payment_amount'] = paymentAmount;
        request.fields['payment_mode'] = paymentMode;
        request.fields['remark'] = remark ?? '';
        request.fields['transaction_id'] = transactionId ?? '';
        request.fields['advance_id'] = advanceId;

        // Add document files
        for (final document in documents) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'documents[]',
              document.path,
            ),
          );
        }

        final streamedResponse = await request.send().timeout(timeout);
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Use regular form request if no documents
        final Map<String, dynamic> requestData = {
          'api_token': token,
          'po_id': poId.toString(),
          'grn_id': grnId?.toString() ?? '',
          'payment_date': paymentDate,
          'payment_amount': paymentAmount,
          'payment_mode': paymentMode,
          'remark': remark ?? '',
          'transaction_id': transactionId ?? '',
          'advance_id': advanceId,
        };

        response = await http.post(
          Uri.parse('$baseUrl/api/materialpo/storePayment'),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
        ).timeout(timeout);
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        
        if (jsonData['status'] == 1) {
          return ApiResponse<Map<String, dynamic>>(
            status: jsonData['status'],
            message: jsonData['message'] ?? '',
            data: jsonData['payment_detail'] ?? {},
          );
        } else {
          return ApiResponse<Map<String, dynamic>>(
            status: jsonData['status'] ?? 0,
            message: jsonData['message'] ?? 'Failed to store payment',
            data: {},
          );
        }
      } else {
        return ApiResponse<Map<String, dynamic>>(
          status: 0,
          message: getErrorMessage(response.statusCode),
          data: {},
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        status: 0,
        message: 'Network error: ${e.toString()}',
        data: {},
      );
    }
  }

  // Get GRN Detail API
  static Future<ApiResponse<GrnDetailModel>?> getGrnDetail({
    required int grnId,
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return null;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/materialgrn/getGrnDetail'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'api_token': token,
          'grn_id': grnId.toString(),
        },
      ).timeout(timeout);

      print('GRN Detail Response Status: ${response.statusCode}');
      print('GRN Detail Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        
        if (jsonData['status'] == 1) {
          return ApiResponse<GrnDetailModel>(
            status: jsonData['status'],
            message: jsonData['message'] ?? '',
            data: GrnDetailModel.fromJson(jsonData['data']),
          );
        } else {
          return ApiResponse<GrnDetailModel>(
            status: jsonData['status'] ?? 0,
            message: jsonData['message'] ?? 'Failed to get GRN details',
            data: null,
          );
        }
      } else {
        return ApiResponse<GrnDetailModel>(
          status: 0,
          message: getErrorMessage(response.statusCode),
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<GrnDetailModel>(
        status: 0,
        message: 'Network error: ${e.toString()}',
        data: null,
      );
    }
  }

  // Get GRN List API
  static Future<ApiResponse<List<dynamic>>?> getGrnList({
    required int siteId,
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return null;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/materialgrn/getGrn'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'api_token': token,
          'site_id': siteId.toString(),
        },
      ).timeout(timeout);


      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        
        if (jsonData['status'] == 1) {
          return ApiResponse<List<dynamic>>(
            status: jsonData['status'],
            message: jsonData['message'] ?? '',
            data: jsonData['data'] ?? [],
          );
        } else {
          return ApiResponse<List<dynamic>>(
            status: jsonData['status'] ?? 0,
            message: jsonData['message'] ?? 'Failed to get GRN list',
            data: [],
          );
        }
      } else {
        return ApiResponse<List<dynamic>>(
          status: 0,
          message: getErrorMessage(response.statusCode),
          data: [],
        );
      }
    } catch (e) {
      return ApiResponse<List<dynamic>>(
        status: 0,
        message: 'Network error: ${e.toString()}',
        data: [],
      );
    }
  }

  // Save GRN API
  static Future<ApiResponse<Map<String, dynamic>>?> saveGrn({
    required String grnDate,
    required String grnNumber,
    required String deliveryChallanNumber,
    required int poId,
    required int vendorId,
    required int siteId,
    String? remarks,
    required List<Map<String, dynamic>> grnMaterials,
    List<Map<String, dynamic>>? grnDocuments,
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return null;
      }

      // Check if we have documents to upload (files)
      bool hasFileDocuments = grnDocuments?.any((doc) => doc['file'] != null) ?? false;

      if (hasFileDocuments) {
        // Use multipart request for file uploads
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/api/materialgrn/saveGrn'),
        );

        // Add basic fields
        request.fields['api_token'] = token;
        request.fields['grn_date'] = grnDate;
        request.fields['grn_number'] = grnNumber;
        request.fields['delivery_challan_number'] = deliveryChallanNumber;
        request.fields['po_id'] = poId.toString();
        request.fields['vendor_id'] = vendorId.toString();
        request.fields['site_id'] = siteId.toString();
        request.fields['remarks'] = remarks ?? '';

        // Add grn_materials
        for (int i = 0; i < grnMaterials.length; i++) {
          final material = grnMaterials[i];
          request.fields['grn_materials[$i][material_id]'] = material['material_id'].toString();
          request.fields['grn_materials[$i][quantity]'] = material['quantity'].toString();
        }

        // Add grn_documents
        if (grnDocuments != null) {
          for (int i = 0; i < grnDocuments.length; i++) {
            final doc = grnDocuments[i];
            if (doc['file'] != null) {
              // Add file
              final file = doc['file'] as File;
              final stream = http.ByteStream(file.openRead());
              final length = await file.length();
              
              final multipartFile = http.MultipartFile(
                'grn_documents[$i][document]',
                stream,
                length,
                filename: file.path.split('/').last,
              );
              
              request.files.add(multipartFile);
              
              // Add description
              if (doc['description'] != null) {
                request.fields['grn_documents[$i][description]'] = doc['description'].toString();
              }
            } else {
              // Add non-file document
              request.fields['grn_documents[$i][document]'] = doc['document']?.toString() ?? '';
              if (doc['description'] != null) {
                request.fields['grn_documents[$i][description]'] = doc['description'].toString();
              }
            }
          }
        }

        print('GRN Multipart Request Fields: ${request.fields}');
        print('GRN Multipart Request Files: ${request.files.length}');

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        print('GRN Response Status: ${response.statusCode}');
        print('GRN Response Body: ${response.body}');
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          
          if (jsonData['status'] == 1) {
            return ApiResponse<Map<String, dynamic>>(
              status: jsonData['status'],
              message: jsonData['message'] ?? '',
              data: jsonData['data'] ?? {},
            );
          } else {
            return ApiResponse<Map<String, dynamic>>(
              status: jsonData['status'] ?? 0,
              message: jsonData['message'] ?? 'Failed to save GRN',
              data: {},
            );
          }
        } else {
          return ApiResponse<Map<String, dynamic>>(
            status: 0,
            message: getErrorMessage(response.statusCode),
            data: {},
          );
        }
      } else {
        // Use regular form data for non-file requests
        final Map<String, dynamic> requestData = {
          'api_token': token,
          'grn_date': grnDate,
          'grn_number': grnNumber,
          'delivery_challan_number': deliveryChallanNumber,
          'po_id': poId.toString(),
          'vendor_id': vendorId.toString(),
          'site_id': siteId.toString(),
          'remarks': remarks ?? '',
        };

        // Add grn_materials
        for (int i = 0; i < grnMaterials.length; i++) {
          final material = grnMaterials[i];
          requestData['grn_materials[$i][material_id]'] = material['material_id'].toString();
          requestData['grn_materials[$i][quantity]'] = material['quantity'].toString();
        }

        // Add grn_documents (non-file)
        if (grnDocuments != null) {
          for (int i = 0; i < grnDocuments.length; i++) {
            final doc = grnDocuments[i];
            requestData['grn_documents[$i][document]'] = doc['document']?.toString() ?? '';
            if (doc['description'] != null) {
              requestData['grn_documents[$i][description]'] = doc['description'].toString();
            }
          }
        }

        print('GRN Request Data: $requestData');

        final response = await http.post(
          Uri.parse('$baseUrl/api/materialgrn/saveGrn'),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
        ).timeout(timeout);
        
        print('GRN Response Status: ${response.statusCode}');
        print('GRN Response Body: ${response.body}');
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          
          if (jsonData['status'] == 1) {
            return ApiResponse<Map<String, dynamic>>(
              status: jsonData['status'],
              message: jsonData['message'] ?? '',
              data: jsonData['data'] ?? {},
            );
          } else {
            return ApiResponse<Map<String, dynamic>>(
              status: jsonData['status'] ?? 0,
              message: jsonData['message'] ?? 'Failed to save GRN',
              data: {},
            );
          }
        } else {
          return ApiResponse<Map<String, dynamic>>(
            status: 0,
            message: getErrorMessage(response.statusCode),
            data: {},
          );
        }
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        status: 0,
        message: 'Network error: ${e.toString()}',
        data: {},
      );
    }
  }

  // Generate Daily Report API
  static Future<Map<String, dynamic>?> generateDailyReport({
    required String apiToken,
    required int siteId,
    required String date,
    required String categoryId,
    required String photos,
    required String material,
    required String manpower,
    required String survey,
    required String userId,
    required String task,
    required String decision,
    required String decisionByAgency,
    required String drawing,
    required String drawingByAgency,
    required String quotation,
    required String quotationByAgency,
    required String selection,
    required String selectionByAgency,
    required String workUpdate,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken.toString(),
        'site_id': siteId.toString(),
        'date': date.toString(),
        'category_id': categoryId.toString(),
        'photos': photos.toString(),
        'material': material.toString(),
        'manpower': manpower.toString(),
        'survey': survey.toString(),
        'user_id': userId.toString(),
        'task': task.toString(),
        'decision': decision.toString(),
        'decision_by_agency': decisionByAgency.toString(),
        'drawing': drawing.toString(),
        'drawing_by_agency': drawingByAgency.toString(),
        'quotation': quotation.toString(),
        'quotation_by_agency': quotationByAgency.toString(),
        'selection': selection.toString(),
        'selection_by_agency': selectionByAgency.toString(),
        'work_update': workUpdate.toString(),
      };

      final queryString = Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query;

      
      final response = await http.post(
        Uri.parse('$baseUrl/api/dailyTaskReport'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: queryString,
      ).timeout(timeout);


      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData;
      } else {

        return null;
      }
    } catch (e) {

      return null;
    }
  }

  // Generate Weekly Report API
  static Future<Map<String, dynamic>?> generateWeeklyReport({
    required String apiToken,
    required int siteId,
    required String startDate,
    required String endDate,
    required String categoryId,
    required String photos,
    required String material,
    required String manpower,
    required String survey,
    required String userId,
    required String task,
    required String decision,
    required String decisionByAgency,
    required String drawing,
    required String drawingByAgency,
    required String quotation,
    required String quotationByAgency,
    required String selection,
    required String selectionByAgency,
    required String workUpdate,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken.toString(),
        'site_id': siteId.toString(),
        'start_date': startDate.toString(),
        'end_date': endDate.toString(),
        'category_id': categoryId.toString(),
        'photos': photos.toString(),
        'material': material.toString(),
        'manpower': manpower.toString(),
        'survey': survey.toString(),
        'user_id': userId.toString(),
        'task': task.toString(),
        'decision': decision.toString(),
        'decision_by_agency': decisionByAgency.toString(),
        'drawing': drawing.toString(),
        'drawing_by_agency': drawingByAgency.toString(),
        'quotation': quotation.toString(),
        'quotation_by_agency': quotationByAgency.toString(),
        'selection': selection.toString(),
        'selection_by_agency': selectionByAgency.toString(),
        'work_update': workUpdate.toString(),
      };

      final queryString = Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query;
      print('Weekly Report Request Data: $requestData');
      print('Weekly Report Query String: $queryString');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/weeklyReport'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: queryString,
      ).timeout(timeout);

      print('Weekly Report API Response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData;
      } else {
        print('Weekly Report API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Weekly Report API Exception: $e');
      return null;
    }
  }

  // Get Billing Addresses API
  static Future<BillingAddressResponse?> getBillingAddresses({
    required String apiToken,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/getBillingAddress'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);


      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return BillingAddressResponse.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Store Billing Address API
  static Future<BillingAddressCreateResponse?> storeBillingAddress({
    required String apiToken,
    required String companyName,
    required String address,
    required String state,
    required String gstin,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'company_name': companyName,
        'address': address,
        'state': state,
        'gstin': gstin,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/storeBillingAddress'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);


      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return BillingAddressCreateResponse.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Update Billing Address API
  static Future<BillingAddressCreateResponse?> updateBillingAddress({
    required String apiToken,
    required int addressId,
    required String companyName,
    required String address,
    required String state,
    required String gstin,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'address_id': addressId.toString(),
        'company_name': companyName,
        'address': address,
        'state': state,
        'gstin': gstin,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/updateBillingAddress'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);


      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return BillingAddressCreateResponse.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Get Terms and Conditions API
  static Future<TermsAndConditionResponse?> getTermsAndConditions({
    required String apiToken,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/material/getTermsAndCondition'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);


      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return TermsAndConditionResponse.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Store and Update Terms and Conditions API
  static Future<Map<String, dynamic>?> storeAndUpdateTermsAndCondition({
    required String apiToken,
    required String termAndCondition,
    int? termId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'term_and_condition': termAndCondition,
      };

      if (termId != null) {
        requestData['term_id'] = termId.toString();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/material/storeAndUpdateTermsAndCondition'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);


      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Get Meeting List API
  static Future<MeetingListResponse?> getMeetingList({
    required String apiToken,
    required int siteId,
    int page = 1,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'site_id': siteId.toString(),
        'page': page.toString(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/meeting/getMeetingList'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);



      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return MeetingListResponse.fromJson(jsonData);
      } else {
        print('Error getting meeting list: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception getting meeting list: $e');
      return null;
    }
  }

  // Get Meeting Detail API
  static Future<MeetingDetailResponse?> getMeetingDetail({
    required String apiToken,
    required int meetingId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'meeting_id': meetingId.toString(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/meeting/getMeetingDetail'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);



      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return MeetingDetailResponse.fromJson(jsonData);
      } else {
        print('Error getting meeting detail: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception getting meeting detail: $e');
      return null;
    }
  }

  // Delete Meeting Discussion API
  static Future<Map<String, dynamic>?> deleteMeetingDiscussion({
    required String apiToken,
    required int meetingDiscussionId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'meeting_discussion_id': meetingDiscussionId.toString(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/meeting/deleteMeetingDiscussion'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);

      print('Delete Meeting Discussion API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData;
      } else {
        print('Error deleting meeting discussion: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception deleting meeting discussion: $e');
      return null;
    }
  }

  // Delete Attachment API
  static Future<Map<String, dynamic>?> deleteAttachment({
    required String apiToken,
    required int meetingAttachmentId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'meeting_attachment_id': meetingAttachmentId.toString(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/meeting/deleteAttachment'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);

      print('Delete Attachment API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData;
      } else {
        print('Error deleting attachment: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception deleting attachment: $e');
      return null;
    }
  }

  // Get Element List API
  static Future<Map<String, dynamic>?> getElementList({
    required String apiToken,
    required int siteId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/stone/elementlist'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'api_token': apiToken,
          'site_id': siteId.toString(),
        },
      ).timeout(timeout);

      print('Get Element List API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error getting element list: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception getting element list: $e');
      return null;
    }
  }

  // Store Element API
  static Future<Map<String, dynamic>?> storeElement({
    required String apiToken,
    required int siteId,
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/stone/storeElement'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'api_token': apiToken,
          'site_id': siteId.toString(),
          'name': name,
        },
      ).timeout(timeout);

      print('Store Element API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error storing element: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception storing element: $e');
      return null;
    }
  }

  // Get Stone Quantity API
  static Future<Map<String, dynamic>?> getStoneQuantity({
    required String apiToken,
    required int siteElementId,
    required int siteId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/stone/getStoneQuantity'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'api_token': apiToken,
          'site_id': siteId.toString(),
          'site_element_id': siteElementId.toString(),
        },
      ).timeout(timeout);

      print('${siteElementId}');
      print('Get Stone Quantity API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error getting stone quantity: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception getting stone quantity: $e');
      return null;
    }
  }

  // Add Stone Quantity API
  static Future<Map<String, dynamic>?> addStoneQuantity({
    required String apiToken,
    required int siteId,
    required int siteElementId,
    required int siteLocationId,
    required int stoneId,
    String? code,
    required double floorArea,
    required String skirtingLength,
    required String skirtingHeight,
    required String skirtingSubtractLength,
    required double skirtingArea,
    required double counterTopAdditional,
    required double wallArea,
    required double totalCounterSkirtingWall,
    required double total,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/stone/stoneQuantity'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'api_token': apiToken,
          'site_id': siteId.toString(),
          'site_element_id': siteElementId.toString(),
          'site_location_id': siteLocationId.toString(),
          'stone_id': stoneId.toString(),
          'code': code ?? '',
          'floor_area': floorArea.toString(),
          'skirting_length': skirtingLength,
          'skirting_height': skirtingHeight,
          'skirting_subtract_length': skirtingSubtractLength,
          'skirting_area': skirtingArea.toString(),
          'counter_top_additional': counterTopAdditional.toString(),
          'wall_area': wallArea.toString(),
          'total_counter_skirting_wall': totalCounterSkirtingWall.toString(),
          'total': total.toString(),
        },
      ).timeout(timeout);

      print('Add Stone Quantity API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error adding stone quantity: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception adding stone quantity: $e');
      return null;
    }
  }

  // Get Stone List API
  static Future<Map<String, dynamic>?> getStoneList({
    required String apiToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/stone/stoneList'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'api_token': apiToken,
        },
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error getting stone list: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception getting stone list: $e');
      return null;
    }
  }

  // Get Site Location List API
  static Future<Map<String, dynamic>?> getSiteLocationList({
    required String apiToken,
    required int siteId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/stone/siteLocationList'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'api_token': apiToken,
          'site_id': siteId.toString(),
        },
      ).timeout(timeout);

      print('Get Site Location List API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error getting site location list: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception getting site location list: $e');
      return null;
    }
  }

  // Store Location API
  static Future<Map<String, dynamic>?> storeLocation({
    required String apiToken,
    required int siteId,
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/stone/storeLocation'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'api_token': apiToken,
          'site_id': siteId.toString(),
          'name': name,
        },
      ).timeout(timeout);

      print('Store Location API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error storing location: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception storing location: $e');
      return null;
    }
  }

  // Store Stone API
  static Future<Map<String, dynamic>?> storeStone({
    required String apiToken,
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/stone/storeStone'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'api_token': apiToken,
          'name': name,
        },
      ).timeout(timeout);

      print('Store Stone API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error storing stone: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception storing stone: $e');
      return null;
    }
  }


  // Update Meeting API
  static Future<Map<String, dynamic>?> updateMeeting(Map<String, dynamic> updateData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/meeting/updateMeeting'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(updateData),
      ).timeout(timeout);

      print('Update Meeting with Files Request Fields: ${updateData}');
      print('Update Meeting API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData;
      } else {
        print('Error updating meeting: ${response.statusCode}');

        return null;
      }
    } catch (e) {
      print('Exception updating meeting: $e');
      return null;
    }
  }

  // Update Meeting with Files API (multipart)
  static Future<Map<String, dynamic>?> updateMeetingWithFiles({
    required Map<String, dynamic> updateData,
    required List<File?> discussionFiles,
    File? voiceNoteFile,
  }) async
  {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/meeting/updateMeeting'),
      );

      // Add all text fields
      request.fields['api_token'] = updateData['api_token'].toString();
      request.fields['site_id'] = updateData['site_id'].toString();
      request.fields['meeting_id'] = updateData['meeting_id'].toString();
      request.fields['architect_company'] = updateData['architect_company'].toString();
      request.fields['meeting_date_time'] = updateData['meeting_date_time'].toString();

      // ✅ Encode lists as JSON so backend can parse them as arrays
      request.fields['clients'] = json.encode(updateData['clients']);
      request.fields['architects'] = json.encode(updateData['architects']);
      request.fields['pmc_members'] = json.encode(updateData['pmc_members']);
      request.fields['contractors'] = json.encode(updateData['contractors']);

      // Add meeting discussions text fields and files
      for (int i = 0; i < (updateData['meeting_discussions'] as List).length; i++) {
        final discussion = updateData['meeting_discussions'][i];
        
        // Add discussion text fields including ID for existing discussions
        if (discussion['id'] != null) {
          request.fields['meeting_discussions[$i][id]'] = discussion['id'].toString();
        }
        request.fields['meeting_discussions[$i][discussion_action]'] = discussion['discussion_action'];
        request.fields['meeting_discussions[$i][action_by]'] = discussion['action_by'];
        request.fields['meeting_discussions[$i][remarks]'] = discussion['remarks'];
        
        // If there's a file for this discussion, add it with the key meeting_discussions[i][document]
        if (i < discussionFiles.length && discussionFiles[i] != null) {
          final file = discussionFiles[i]!;
          request.files.add(
            await http.MultipartFile.fromPath(
              'meeting_discussions[$i][document]',
              file.path,
            ),
          );
        }
      }

      // Add voice note file if provided
      if (voiceNoteFile != null && voiceNoteFile.existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'voice_note',
            voiceNoteFile.path,
          ),
        );
      }

      print('Update Meeting with Files Request Fields: ${request.fields}');
      print('Update Meeting with Files Request Files: ${request.files.length} files');

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      print('Update Meeting with Files API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error updating meeting with files: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception updating meeting with files: $e');
      return null;
    }
  }



  // Save Meeting API
  static Future<Map<String, dynamic>?> saveMeeting(Map<String, dynamic> meetingData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/meeting/saveMeeting'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(meetingData),
      ).timeout(timeout);

      print('Save Meeting API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error saving meeting: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception saving meeting: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> saveMeetingWithFiles({
    required Map<String, dynamic> meetingData,
    required List<File?> discussionFiles,
    File? voiceNoteFile,
  }) async
  {
    try {
      final uri = Uri.parse('$baseUrl/api/meeting/saveMeeting');
      final request = http.MultipartRequest('POST', uri);

      // Required text fields
      if (meetingData['api_token'] != null) {
        request.fields['api_token'] = meetingData['api_token'].toString();
      }
      if (meetingData['site_id'] != null) {
        request.fields['site_id'] = meetingData['site_id'].toString();
      }
      if (meetingData['architect_company'] != null) {
        request.fields['architect_company'] = meetingData['architect_company'].toString();
      }
      if (meetingData['meeting_date_time'] != null) {
        request.fields['meeting_date_time'] = meetingData['meeting_date_time'].toString();
      }
      if (meetingData['meeting_place'] != null) {
        request.fields['meeting_place'] = meetingData['meeting_place'].toString();
      }

      // ✅ Encode lists as JSON so backend can parse them as arrays
      if (meetingData['clients'] != null) {
        request.fields['clients'] = json.encode(meetingData['clients']);
      }
      if (meetingData['architects'] != null) {
        request.fields['architects'] = json.encode(meetingData['architects']);
      }
      if (meetingData['pmc_members'] != null) {
        request.fields['pmc_members'] = json.encode(meetingData['pmc_members']);
      }
      if (meetingData['contractors'] != null) {
        request.fields['contractors'] = json.encode(meetingData['contractors']);
      }

      // ✅ Handle meeting discussions
      final discussions = meetingData['meeting_discussions'] as List?;
      if (discussions != null && discussions.isNotEmpty) {
        for (int i = 0; i < discussions.length; i++) {
          final discussion = discussions[i];
          if (discussion['discussion_action'] != null) {
            request.fields['meeting_discussions[$i][discussion_action]'] =
                discussion['discussion_action'].toString();
          }
          if (discussion['action_by'] != null) {
            request.fields['meeting_discussions[$i][action_by]'] =
                discussion['action_by'].toString();
          }
          if (discussion['remarks'] != null) {
            request.fields['meeting_discussions[$i][remarks]'] =
                discussion['remarks'].toString();
          }

          // Attach discussion file (if exists)
          if (i < discussionFiles.length && discussionFiles[i] != null) {
            final file = discussionFiles[i]!;
            request.files.add(
              await http.MultipartFile.fromPath(
                'meeting_discussions[$i][document]',
                file.path,
              ),
            );
          }
        }
      }

      // ✅ Add voice note if available
      if (voiceNoteFile != null && voiceNoteFile.existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath('voice_note', voiceNoteFile.path),
        );
      }

      print('--- Save Meeting with Files Request ---');
      print('Fields: ${request.fields}');
      print('Files: ${request.files.length} attached');
      print('--------------------------------------');

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      print('Save Meeting with Files API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error saving meeting with files: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception saving meeting with files: $e');
      return null;
    }
  }


  // Save Meeting Attachment API
  static Future<Map<String, dynamic>?> saveMeetingAttachment({
    required String apiToken,
    required int meetingDiscussionId,
    required File file,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/meeting/saveAttachment'),
      );

      request.headers['Accept'] = 'application/json';
      request.fields['api_token'] = apiToken;
      request.fields['meeting_discussion_id'] = meetingDiscussionId.toString();

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
        ),
      );

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      print('Save Attachment API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error saving attachment: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception saving attachment: $e');
      return null;
    }
  }

  // Create Purchase Order API
  static Future<ApiResponse<Map<String, dynamic>>> createPurchaseOrder({
    required String apiToken,
    required String siteId,
    required String purchaseOrderId,
    required String vendorId,
    required String expectedDeliveryDate,
    required String billingAddressId,
    required String deliveryAddress,
    required String deliveryState,
    required String deliveryContactName,
    required String deliveryContactNo,
    required List<Map<String, dynamic>> materials,
    required String cgst,
    required String sgst,
    required String igst,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'site_id': siteId,
        'purchase_order_id': purchaseOrderId,
        'vendor_id': vendorId,
        'expected_delivery_date': expectedDeliveryDate,
        'billing_address_id': billingAddressId,
        'delivery_address': deliveryAddress,
        'delivery_state': deliveryState,
        'delivery_contact_name': deliveryContactName,
        'delivery_contact_no': deliveryContactNo,
        'materials': materials, // Send as array, not JSON string
        'cgst': cgst,
        'sgst': sgst,
        'igst': igst,
      };

      // Debug: Print request data
      print('API Request Data:');
      print(json.encode(requestData));

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/material/createPurchaseOrder'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(requestData),
          )
          .timeout(timeout);

      // Debug: Print response
      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          return ApiResponse(
            status: jsonData['status'] ?? 0,
            message: jsonData['message'] ?? '',
            data: jsonData,
          );
        } catch (e) {
          print('JSON Parse Error in createPurchaseOrder: $e');
          print('Response Body: ${response.body}');
          return ApiResponse(
            status: 0,
            message: 'Invalid response format from server',
            data: null,
          );
        }
      } else {
        return ApiResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Network error. Please try again.',
        data: null,
      );
    }
  }

  // Generate Order ID API
  static Future<ApiResponse<Map<String, dynamic>>> generateOrderId({
    required String apiToken,
    required String type, // 'po', 'payment', 'grn'
  }) async {


    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'type': type,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/material/generateAllOrderId'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: requestData,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return ApiResponse(
          status: jsonData['status'] ?? 0,
          message: jsonData['message'] ?? '',
          data: jsonData,
        );
      } else {
        return ApiResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse(
        status: 0,
        message: 'Network error. Please try again.',
        data: null,
      );
    }
  }

  // Get Site Vendors API
  static Future<SiteVendorResponse?> getSiteVendors({
    required int siteId,
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return SiteVendorResponse(
          status: 'error',
          message: 'Authentication token not found. Please login again.',
          data: [],
        );
      }

      final Map<String, dynamic> requestData = {
        'api_token': token,
        'site_id': siteId.toString(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/getMaterialVendor'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return SiteVendorResponse.fromJson(jsonData);
      } else {
        return SiteVendorResponse(
          status: 'error',
          message: _parseApiErrorMessage(response.body, response.statusCode),
          data: [],
        );
      }
    } catch (e) {
      return SiteVendorResponse(
        status: 'error',
        message: 'Network error. Please check your connection and try again.',
        data: [],
      );
    }
  }

  // Save Site Vendor API
  static Future<Map<String, dynamic>?> saveSiteVendor({
    required int siteId,
    required String name,
    required String mobile,
    required String email,
    String? gstNo,
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return {
          'status': 'error',
          'message': 'Authentication token not found. Please login again.',
          'data': null,
        };
      }

      final Map<String, dynamic> requestData = {
        'api_token': token,
        'site_id': siteId.toString(),
        'name': name,
        'mobile': mobile,
        'email': email,
        if (gstNo != null && gstNo.isNotEmpty) 'gst_no': gstNo,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/saveMaterialVendor'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);

      log("Add site vendor response == ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData; // Return the full response
      } else {
        return {
          'status': 'error',
          'message': _parseApiErrorMessage(response.body, response.statusCode),
          'data': null,
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error. Please check your connection and try again.',
        'data': null,
      };
    }
  }

  // Update Site Vendor API
  static Future<Map<String, dynamic>?> updateSiteVendor({
    required int vendorId,
    required int siteId,
    required String name,
    required String mobile,
    required String email,
    String? gstNo,
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return {
          'status': 'error',
          'message': 'Authentication token not found. Please login again.',
          'data': null,
        };
      }

      final Map<String, dynamic> requestData = {
        'api_token': token,
        'vendor_id': vendorId.toString(),
        'site_id': siteId.toString(),
        'name': name,
        'mobile': mobile,
        'email': email,
        if (gstNo != null && gstNo.isNotEmpty) 'gst_no': gstNo,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/updateMaterialVendor'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData; // Return the full response
      } else {
        return {
          'status': 'error',
          'message': _parseApiErrorMessage(response.body, response.statusCode),
          'data': null,
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error. Please check your connection and try again.',
        'data': null,
      };
    }
  }

  // Store Quality Check API
  static Future<ApiResponse<Map<String, dynamic>>> storeQualityCheck({
    required String apiToken,
    required int taskId,
    required String checkType,
    required String date,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'task_id': taskId.toString(),
        'check_type': checkType,
        'date': date,
        'items': json.encode(items),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/quality/storeQualityCheck'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return ApiResponse.fromJson(jsonData, null);
      } else {
        return ApiResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return ApiResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
        );
      }
      return ApiResponse(
        status: 0,
        message: 'Something went wrong. $e',
      );
    }
  }

  // Update Quality Check API
  static Future<ApiResponse<Map<String, dynamic>>> updateQualityCheck({
    required String apiToken,
    required int taskId,
    required String checkType,
    required int qualityCheckId,
    required String date,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'task_id': taskId.toString(),
        'check_type': checkType,
        'quality_check_id': qualityCheckId.toString(),
        'date': date,
        'items': json.encode(items),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/quality/updateQualityCheck'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return ApiResponse.fromJson(jsonData, null);
      } else {
        return ApiResponse(
          status: 0,
          message: getErrorMessage(response.statusCode),
        );
      }
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        return ApiResponse(
          status: 0,
          message: 'No internet connection. Please check your network.',
        );
      }
      return ApiResponse(
        status: 0,
        message: 'Something went wrong. $e',
      );
    }
  }

  // Delete Site Vendor API
  static Future<Map<String, dynamic>?> deleteSiteVendor({
    required int vendorId,
  }) async {
    try {
      final token = await AuthService.currentToken;
      if (token == null) {
        return {
          'status': 'error',
          'message': 'Authentication token not found. Please login again.',
          'success': false,
        };
      }

      final Map<String, dynamic> requestData = {
        'api_token': token,
        'vendor_id': vendorId.toString(),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/deleteMaterialVendor'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: Uri(queryParameters: requestData.map((key, value) => MapEntry(key, value.toString()))).query,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return jsonData; // Return the full response
      } else {
        return {
          'status': 'error',
          'message': _parseApiErrorMessage(response.body, response.statusCode),
          'success': false,
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error. Please check your connection and try again.',
        'success': false,
      };
    }
  }


} 