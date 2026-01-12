import 'package:shared_preferences/shared_preferences.dart';

// Key used to store the user ID in local storage
const String _kUserIdKey = 'loggedInUserId';
// Key used to store the user's login status 
const String _kIsLoggedInKey = 'isUserLoggedIn';

class AuthStorageService {
    
    // 1. SAVE the user ID and login status
    /// Saves the authenticated user ID to SharedPreferences.
    Future<void> saveUserData(String userId) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kUserIdKey, userId); 
        await prefs.setBool(_kIsLoggedInKey, true); 
        print('User Data saved: ID=$userId');
    }

    // ALIAS for saveUserData to prevent errors in LoginScreen
    Future<void> saveUserId(String userId) async {
        await saveUserData(userId);
    }

    // 2. RETRIEVE the user ID for screens like the Profile
    /// Retrieves the saved user ID. Returns null if not found.
    Future<String?> getUserId() async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString(_kUserIdKey); 
        return userId;
    }
    
    // 3. CHECK if the user is currently logged in
    /// Checks the login flag.
    Future<bool> isLoggedIn() async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        return prefs.getBool(_kIsLoggedInKey) ?? false;
    }
    
    // 4. CLEAR all user data on logout
    /// Removes all authentication tokens/IDs.
    Future<void> clearUserData() async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove(_kUserIdKey);
        await prefs.remove(_kIsLoggedInKey);
        print('User data cleared (logged out).');
    }

    // --- CRITICAL FIX FOR YOUR ERROR ---
    /// Matches the method name called in EditableProfileScreen
    Future<void> clearAuthData() async {
        await clearUserData();
    }
}