import Flutter
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import GoogleSignIn
import FBSDKCoreKit

import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyD16-TRK-OlZwz3wgZCJ8c5_CEWQ-zGkQU")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // URL handling for Google Sign In and Facebook Login
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // Google Sign In için
    if GIDSignIn.sharedInstance.handle(url) {
      return true
    }
    
    // Facebook Login için
    if ApplicationDelegate.shared.application(app, open: url, options: options) {
      return true
    }
    
    return super.application(app, open: url, options: options)
  }
}
