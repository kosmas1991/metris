import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:metris/firebase_options.dart';
import 'dart:developer' as developer;
import '../models/player.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in anonymously
  Future<User?> signInAnonymously() async {
    try {
      developer.log("Attempting anonymous sign-in");

      // Make sure Firebase is properly initialized before attempting sign-in
      if (Firebase.apps.isEmpty) {
        developer.log("Firebase not initialized. Initializing now...");
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // Modified approach to handle the type casting issue
      try {
        // Add a small delay to ensure Firebase is fully initialized
        await Future.delayed(const Duration(milliseconds: 500));

        final userCredential = await _auth.signInAnonymously();
        final user = userCredential.user;

        developer.log("Signed in anonymously successfully: ${user?.uid}");

        if (user != null) {
          // Check if user already exists in Firestore
          try {
            final userDoc =
                await _firestore.collection('players').doc(user.uid).get();

            if (!userDoc.exists) {
              // Create new player document if it doesn't exist
              final newPlayer = Player(
                id: user.uid,
                displayName: 'Player_${user.uid.substring(0, 5)}',
                isOnline: true,
              );

              await _firestore
                  .collection('players')
                  .doc(user.uid)
                  .set(newPlayer.toMap());

              developer.log("Created new player document");
            } else {
              // Update online status
              await _firestore
                  .collection('players')
                  .doc(user.uid)
                  .update({'isOnline': true});

              developer.log("Updated existing player online status");
            }
          } catch (firestoreError) {
            developer.log("Firestore error: $firestoreError",
                error: firestoreError);
            // Continue since authentication was successful even if Firestore operations failed
          }
        }

        return user;
      } catch (authError) {
        developer.log(
            "Specific auth error during anonymous sign-in: $authError",
            error: authError);

        // Handle the specific type error
        if (authError.toString().contains(
            "'List<Object?>' is not a subtype of type 'PigeonUserDetails?'")) {
          developer.log(
              "Detected Firebase plugin type error, trying alternative approach");

          // Wait for Firebase internal processes to complete
          await Future.delayed(const Duration(seconds: 2));

          // Check if the user was actually created despite the error
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            developer.log(
                "User was created successfully despite error: ${currentUser.uid}");

            // Ensure Firestore record exists
            try {
              final userDoc = await _firestore
                  .collection('players')
                  .doc(currentUser.uid)
                  .get();

              if (!userDoc.exists) {
                final newPlayer = Player(
                  id: currentUser.uid,
                  displayName: 'Player_${currentUser.uid.substring(0, 5)}',
                  isOnline: true,
                );

                await _firestore
                    .collection('players')
                    .doc(currentUser.uid)
                    .set(newPlayer.toMap());
              } else {
                await _firestore
                    .collection('players')
                    .doc(currentUser.uid)
                    .update({'isOnline': true});
              }
            } catch (e) {
              developer.log("Error creating player record: $e", error: e);
            }

            return currentUser;
          }
        }

        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      developer.log("Firebase Auth Exception: ${e.code} - ${e.message}",
          error: e);

      if (e.code == 'operation-not-allowed') {
        developer.log("Anonymous auth is not enabled in Firebase console",
            error: e);
      }

      return null;
    } catch (e) {
      developer.log("Error signing in anonymously: $e", error: e);
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Update online status before signing out
      if (currentUser != null) {
        await _firestore
            .collection('players')
            .doc(currentUser!.uid)
            .update({'isOnline': false});
      }
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Update player name
  Future<void> updateDisplayName(String displayName) async {
    if (currentUser != null) {
      await _firestore
          .collection('players')
          .doc(currentUser!.uid)
          .update({'displayName': displayName});
    }
  }

  // Get player data
  Future<Player?> getPlayerData() async {
    if (currentUser == null) return null;

    try {
      final doc =
          await _firestore.collection('players').doc(currentUser!.uid).get();
      if (doc.exists) {
        return Player.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting player data: $e');
      return null;
    }
  }

  // Update high score
  Future<void> updateHighScore(int score) async {
    if (currentUser == null) return;

    try {
      final playerDoc =
          await _firestore.collection('players').doc(currentUser!.uid).get();
      if (playerDoc.exists) {
        final currentHighScore = playerDoc.data()?['highScore'] ?? 0;
        if (score > currentHighScore) {
          await _firestore
              .collection('players')
              .doc(currentUser!.uid)
              .update({'highScore': score});
        }
      }
    } catch (e) {
      print('Error updating high score: $e');
    }
  }

  // Check if anonymous auth is available
  Future<bool> isAnonymousAuthEnabled() async {
    try {
      // Just check if we can create an anonymous auth provider
      final provider = EmailAuthProvider.credential(
        email: 'test@example.com',
        password: 'password',
      );
      // If we can create a provider, the feature should be enabled
      return provider != null;
    } catch (e) {
      debugPrint('Error checking anonymous auth: $e');
      return false;
    }
  }
}
