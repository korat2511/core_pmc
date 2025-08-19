import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/site_list_response.dart';
import '../models/site_user_response.dart';
import '../models/site_album_response.dart';
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
    String search = '',
    int userType = 0,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
        'site_id': siteId.toString(),
      };

      // Add search filter if provided
      if (search.isNotEmpty) {
        requestData['search'] = search;
      }

      // Add user type filter if provided
      if (userType > 0) {
        requestData['user_type'] = userType.toString();
      }

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
    String search = '',
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'api_token': apiToken,
      };

      // Add search filter if provided
      if (search.isNotEmpty) {
        requestData['search'] = search;
      }

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
} 