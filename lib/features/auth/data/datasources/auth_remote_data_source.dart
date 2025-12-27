import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:googleapis/forms/v1.dart' as forms;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import '../../../../core/utils/crashlytics_helper.dart';

abstract class IAuthRemoteDataSource {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<User?> signInWithGoogle();
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> registerWithEmailAndPassword(String email, String password);
  Future<void> changePassword(String newPassword);
  Future<void> signOut();
  Future<AuthClient?> requestFormsAccess();
  Future<String> createSecondaryUser(String email, String password);
}

class AuthRemoteDataSourceImpl implements IAuthRemoteDataSource {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final CrashlyticsHelper _crashlytics;
  bool _areScopesGranted = false;

  AuthRemoteDataSourceImpl({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    CrashlyticsHelper? crashlytics,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email']),
        _crashlytics = crashlytics ?? CrashlyticsHelper();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final cred = await _auth.signInWithPopup(googleProvider);
        if (cred.user != null) {
          await _crashlytics.setUserIdentifier(cred.user!.uid);
          await _crashlytics.log('User signed in with Google (Web): ${cred.user!.email}');
        }
        return cred.user;
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        if (userCredential.user != null) {
          await _crashlytics.setUserIdentifier(userCredential.user!.uid);
          await _crashlytics.log('User signed in with Google: ${userCredential.user!.email}');
        }
        return userCredential.user;
      }
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack, reason: 'Error signing in with Google');
      rethrow;
    }
  }

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (cred.user != null) {
        await _crashlytics.setUserIdentifier(cred.user!.uid);
        await _crashlytics.log('User signed in with email: ${cred.user!.email}');
        return cred.user!;
      } else {
        throw FirebaseAuthException(code: 'user-not-found', message: 'User not found after sign in');
      }
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack, reason: 'Error signing in with email');
      rethrow;
    }
  }

  @override
  Future<User> registerWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (cred.user != null) {
        await _crashlytics.setUserIdentifier(cred.user!.uid);
        await _crashlytics.log('User registered: ${cred.user!.email}');
        return cred.user!;
      } else {
        throw FirebaseAuthException(code: 'registration-failed', message: 'User creation failed');
      }
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack, reason: 'Error registering with email');
      rethrow;
    }
  }

  @override
  Future<void> changePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');
      await user.updatePassword(newPassword);
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack, reason: 'Error changing password');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      await _crashlytics.setUserIdentifier("");
      await _crashlytics.log('User signed out');
    } catch (e, stack) {
      await _crashlytics.recordError(e, stack, reason: 'Error signing out');
      rethrow;
    }
  }

  @override
  Future<AuthClient?> requestFormsAccess() async {
    try {
      debugPrint("AuthRemoteDataSource: requestFormsAccess started.");
      if (_googleSignIn.currentUser == null) {
        debugPrint("AuthRemoteDataSource: No Google user. Attempting silent sign-in...");
        await _googleSignIn.signInSilently();
      }

      if (_googleSignIn.currentUser == null) {
         debugPrint("AuthRemoteDataSource: Silent sign-in failed. Triggering interactive sign-in...");
         await _googleSignIn.signIn();
      }

      if (_googleSignIn.currentUser == null) {
         debugPrint("AuthRemoteDataSource: User still null after sign-in attempt.");
         return null;
      }

      final scopes = [
        forms.FormsApi.formsBodyReadonlyScope,
        forms.FormsApi.formsResponsesReadonlyScope,
        drive.DriveApi.driveReadonlyScope, 
      ];
      
      if (!_areScopesGranted) {
         debugPrint("AuthRemoteDataSource: Requesting scopes for ${_googleSignIn.currentUser?.email}...");
         final bool isAuthorized = await _googleSignIn.requestScopes(scopes);
         if (isAuthorized) {
           _areScopesGranted = true;
         } else {
           debugPrint("AuthRemoteDataSource: User declined Forms access.");
           return null;
         }
      } else {
         debugPrint("AuthRemoteDataSource: Scopes already granted (cached). Skipping request.");
      }

      debugPrint("AuthRemoteDataSource: Scopes authorized. Getting authenticated client...");
      return await _googleSignIn.authenticatedClient();
    } catch (e) {
      debugPrint("Error requesting Forms access: $e");
      rethrow;
    }
  }

  @override
  Future<String> createSecondaryUser(String email, String password) async {
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      final auth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
          await _crashlytics.log('Secondary user created: ${credential.user!.email}');
          return credential.user!.uid;
      } else {
        throw FirebaseAuthException(code: 'creation-failed', message: 'Failed to create secondary user');
      }

    } catch (e, stack) {
      await _crashlytics.recordError(e, stack, reason: 'Error creating secondary user');
      rethrow;
    } finally {
      await secondaryApp?.delete();
    }
  }
}
