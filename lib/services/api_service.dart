import 'dart:convert';
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
import '../models/manpower_response.dart';
import '../models/tag_response.dart';
import '../models/task_response.dart';
import '../models/task_detail_model.dart';
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

      print('API Request: $requestData');

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
      print('Assign Site API Error: $e');
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

      print('Remove User from Site API Request: $requestData');

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
      print('Remove User from Site API Error: $e');
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
      print('Get Categories API Error: $e');
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

      print('Create Category API Request: $requestData');

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

      print('Create Category API Response Status: ${response.statusCode}');
      print('Create Category API Response Body: ${response.body}');

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
      print('Create Category API Error: $e');
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

      print('Update Category API Request: $requestData');

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

      print('Update Category API Response Status: ${response.statusCode}');
      print('Update Category API Response Body: ${response.body}');

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
      print('Update Category API Error: $e');
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

      print('Delete Category API Request: $requestData');

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

      print('Delete Category API Response Status: ${response.statusCode}');
      print('Delete Category API Response Body: ${response.body}');

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
      print('Delete Category API Error: $e');
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
  }) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/createSite'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $apiToken',
        'Accept': 'application/json',
      });

      // Add text fields
      request.fields.addAll({
        'site_name': siteName,
        'client_name': clientName,
        'architect_name': architectName,
        'start_date': startDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
        'end_date': endDate.toIso8601String().split('T')[0], // YYYY-MM-DD format
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'address': address,
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
} 