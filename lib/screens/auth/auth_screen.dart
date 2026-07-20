import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get isSignedIn => _auth.currentUser != null;

  User? get currentUser => _auth.currentUser;

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'Invalid email format.';
        case 'user-not-found':
        case 'invalid-credential':
          return 'No account found for this email. Please create one first.';
        case 'wrong-password':
          return 'Wrong password.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return e.message ?? 'An error occurred during sign in.';
      }
    } catch (_) {
      return 'An unexpected error occurred.';
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'Invalid email format.';
        case 'email-already-in-use':
          return 'This email is already registered. Please sign in.';
        case 'weak-password':
          return 'Password must be at least 6 characters.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return e.message ?? 'An error occurred during sign up.';
      }
    } catch (_) {
      return 'An unexpected error occurred.';
    }
  }

  Future<String?> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'Invalid email format.';
        case 'user-not-found':
          return 'No account found for this email.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return e.message ?? 'An error occurred while resetting password.';
      }
    } catch (_) {
      return 'An unexpected error occurred.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'Please sign in again before deleting your account.';
      }
      return e.message ?? 'Error deleting account.';
    } catch (_) {
      return 'Error deleting account.';
    }
  }
}