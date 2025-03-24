import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class DebugService {
  static void printFirebaseStatus() {
    try {
      final FirebaseApp app = Firebase.app();
      developer.log("Firebase initialized successfully");
      developer.log("Firebase app name: ${app.name}");
      developer.log("Firebase options: ${app.options}");

      // Check auth status
      final auth = FirebaseAuth.instance;
      developer.log("Auth initialized: ${auth != null}");
      developer.log("Current user: ${auth.currentUser?.uid ?? 'No user'}");
    } catch (e) {
      developer.log("Error checking Firebase status: $e", error: e);
    }
  }

  static void checkAnonymousAuthEnabled() {
    try {
      developer.log("Checking if anonymous auth is enabled...");

      // Add a delay to ensure Firebase is fully initialized
      Future.delayed(const Duration(milliseconds: 500), () {
        FirebaseAuth.instance.signInAnonymously().then((result) {
          developer.log("Anonymous auth is enabled, user: ${result.user?.uid}");
          // Sign out to clean up
          FirebaseAuth.instance.signOut();
        }).catchError((e) {
          if (e is FirebaseAuthException && e.code == 'operation-not-allowed') {
            developer.log("Anonymous auth is not enabled in Firebase console",
                error: e);
          } else {
            developer.log("Error testing anonymous auth: $e", error: e);

            // Check if user was created despite error
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              developer.log(
                  "User was actually created despite error: ${currentUser.uid}");
              // Sign out to clean up
              FirebaseAuth.instance.signOut();
            }
          }
        });
      });
    } catch (e) {
      developer.log("Error checking anonymous auth: $e", error: e);
    }
  }
}
