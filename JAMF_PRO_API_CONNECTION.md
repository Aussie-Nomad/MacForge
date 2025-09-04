# JAMF Pro API Connection Guide

## 🔗 **Overview**

This document outlines the improvements made to MacForge's JAMF Pro integration to resolve server connection issues and ensure compatibility with both Classic and v1 API endpoints.

## 🐛 **Issues Identified**

### **Server Connection Problems**
- **Server Ping Failed**: The original implementation only tested `api/v1/ping` endpoint
- **Single Endpoint Testing**: No fallback mechanism for different JAMF Pro versions
- **Strict Response Codes**: Only accepted HTTP 200, rejecting valid 401/403 responses

### **API Endpoint Compatibility**
- **Version Mismatch**: Different JAMF Pro versions use different API structures
- **Endpoint Variations**: Classic vs. v1 API have different URL patterns
- **Response Format Differences**: JSON structure varies between API versions

## ✅ **Solutions Implemented**

### **1. Multi-Endpoint Ping Testing**
The authentication service now tests multiple endpoints to determine server connectivity:

```swift
let pingEndpoints = [
    "api/v1/ping",           // Modern JAMF Pro v1 API
    "JSSResource/accounts",  // Classic JAMF Pro
    "api/ping"               // Alternative ping endpoint
]
```

### **2. Flexible Response Code Acceptance**
Server connectivity is now confirmed with multiple valid response codes:

- **HTTP 200**: Server is reachable and responding
- **HTTP 401**: Server is reachable but requires authentication (valid for connectivity test)
- **HTTP 403**: Server is reachable but access is forbidden (valid for connectivity test)

### **3. Enhanced Error Handling**
Improved error messages and fallback mechanisms for different failure scenarios.

## 🔧 **Technical Implementation**

### **Authentication Service Updates**
- **Multiple Ping Endpoints**: Tests various JAMF Pro endpoints for connectivity
- **Timeout Management**: 10-second timeout for each endpoint test
- **Graceful Degradation**: Continues testing if one endpoint fails

### **Connection Validation Flow**
1. **URL Normalization**: Ensures proper URL format (adds https:// if missing)
2. **Multi-Endpoint Testing**: Tests multiple endpoints for server reachability
3. **Response Code Analysis**: Accepts various valid response codes
4. **Fallback Handling**: Gracefully handles different JAMF Pro configurations

## 📋 **JAMF Pro Version Compatibility**

### **JAMF Pro 10.x (Classic API)**
- **Ping Endpoint**: `JSSResource/accounts`
- **Profile Endpoints**: `JSSResource/osxconfigurationprofiles/*`
- **Response Format**: Direct XML/JSON responses

### **JAMF Pro 11.x+ (v1 API)**
- **Ping Endpoint**: `api/v1/ping`
- **Profile Endpoints**: `api/v1/os-x-configuration-profiles`
- **Response Format**: Wrapped JSON with metadata

### **Hybrid Installations**
- **Auto-Detection**: Tests both API versions
- **Fallback Mechanism**: Uses classic API if v1 is unavailable
- **Graceful Degradation**: Maintains functionality across versions

## 🚀 **Usage Instructions**

### **For End Users**
1. **Enter JAMF Pro Server URL**: Use the full URL (e.g., `https://your-server.jamfcloud.com`)
2. **Authentication**: Use either OAuth or Basic authentication
3. **Connection Test**: The system automatically tests multiple endpoints
4. **Debug Information**: View detailed connection status in the debug panel

### **For Administrators**
1. **Firewall Configuration**: Ensure ports 443 (HTTPS) and 8443 (alternative) are open
2. **Network Access**: Verify network connectivity to JAMF Pro server
3. **API Permissions**: Ensure user account has appropriate API access rights
4. **SSL Certificates**: Verify SSL certificate validity and trust

## 🔍 **Troubleshooting**

### **Common Connection Issues**

#### **"Server ping: FAILED - Server is unreachable"**
- **Check Network**: Verify network connectivity to JAMF Pro server
- **Firewall**: Ensure corporate firewall allows HTTPS traffic
- **DNS Resolution**: Verify server hostname resolves correctly
- **SSL/TLS**: Check for SSL certificate issues

#### **"Auth endpoint: REACHABLE" but "HTTP 401"**
- **Credentials**: Verify username/password or OAuth credentials
- **Permissions**: Ensure user account has API access rights
- **Authentication Method**: Confirm correct authentication type (Basic vs. OAuth)

#### **"JSSResource/*: HTTP 401"**
- **API Access**: Verify user has access to specific JAMF Pro resources
- **Token Expiry**: Check if authentication token has expired
- **Resource Permissions**: Ensure user can access configuration profiles

### **Debug Information**
The debug panel provides detailed information about:
- **Server Connectivity**: Ping test results for multiple endpoints
- **Authentication Endpoints**: OAuth and Basic auth endpoint status
- **Resource Access**: Specific JAMF Pro resource endpoint responses
- **Timestamps**: When each test was performed

## 📚 **API Reference**

### **JAMF Pro Classic API**
- **Base URL**: `https://your-server.com:8443`
- **Endpoints**: `JSSResource/*`
- **Authentication**: Basic Auth or OAuth
- **Response Format**: XML or JSON

### **JAMF Pro v1 API**
- **Base URL**: `https://your-server.com:8443`
- **Endpoints**: `api/v1/*`
- **Authentication**: OAuth (preferred) or Basic Auth
- **Response Format**: JSON with metadata wrapper

## 🔮 **Future Enhancements**

### **Planned Improvements**
1. **API Version Auto-Detection**: Automatically detect and use appropriate API version
2. **Enhanced Error Messages**: More specific error messages for different failure types
3. **Connection Pooling**: Optimize connection reuse for better performance
4. **Retry Logic**: Implement exponential backoff for failed connections

### **Monitoring & Logging**
1. **Connection Metrics**: Track connection success/failure rates
2. **Performance Monitoring**: Monitor API response times
3. **Error Logging**: Detailed logging for troubleshooting
4. **Health Checks**: Periodic connection health monitoring

## 📞 **Support**

For additional support with JAMF Pro integration:
1. **Check Debug Panel**: Review detailed connection information
2. **Verify Credentials**: Ensure authentication details are correct
3. **Network Testing**: Test basic connectivity to JAMF Pro server
4. **JAMF Documentation**: Refer to official JAMF Pro API documentation
