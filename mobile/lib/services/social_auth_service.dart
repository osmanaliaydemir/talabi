import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:mobile/services/api_service.dart';

class SocialAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  final ApiService _apiService = ApiService();

  // Google Sign In
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Send to backend
      final response = await _apiService.externalLogin(
        provider: 'Google',
        idToken: googleAuth.idToken ?? '',
        email: googleUser.email,
        fullName: googleUser.displayName ?? googleUser.email,
      );

      return response;
    } catch (e) {
      print('🔴 [SOCIAL_AUTH] Google Sign In Error: $e');
      rethrow;
    }
  }

  // Apple Sign In
  Future<Map<String, dynamic>?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.talabi.mobile',
          redirectUri: Uri.parse(
            'https://talabi-app.firebaseapp.com/__/auth/handler',
          ),
        ),
      );

      // Construct full name from Apple's name parts
      String? fullName;
      if (credential.givenName != null || credential.familyName != null) {
        fullName =
            '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
                .trim();
      }

      // Send to backend
      final response = await _apiService.externalLogin(
        provider: 'Apple',
        idToken: credential.identityToken ?? '',
        email: credential.email ?? '',
        fullName: fullName ?? credential.email ?? 'Apple User',
      );

      return response;
    } catch (e) {
      print('🔴 [SOCIAL_AUTH] Apple Sign In Error: $e');
      rethrow;
    }
  }

  // Facebook Sign In
  Future<Map<String, dynamic>?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        // User cancelled or error
        return null;
      }

      // Get user data
      final userData = await FacebookAuth.instance.getUserData();

      // Send to backend
      final response = await _apiService.externalLogin(
        provider: 'Facebook',
        idToken: result.accessToken?.token ?? '',
        email: userData['email'] ?? '',
        fullName: userData['name'] ?? userData['email'] ?? 'Facebook User',
      );

      return response;
    } catch (e) {
      print('🔴 [SOCIAL_AUTH] Facebook Sign In Error: $e');
      rethrow;
    }
  }

  // Sign out from all providers
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
      // Apple doesn't have a sign out method
    } catch (e) {
      print('🔴 [SOCIAL_AUTH] Sign Out Error: $e');
    }
  }
}
