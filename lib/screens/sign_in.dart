import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void>? _googleInitialization;

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool busy = false;
  String? error;

  Future<void> signIn() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      } else {
        final signIn = GoogleSignIn.instance;
        _googleInitialization ??= signIn.initialize(
          serverClientId:
              '686143109566-l010gs38lr6ur54k6hi1dhqprehfmk30.apps.googleusercontent.com',
        );
        await _googleInitialization;
        final account = await signIn.authenticate();
        final credential = GoogleAuthProvider.credential(
          idToken: account.authentication.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.local_florist, size: 64),
              const SizedBox(height: 16),
              Text('Flora', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Sign in to your shop'),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: busy ? null : signIn,
                icon: const Icon(Icons.login),
                label: Text(busy ? 'Signing in…' : 'Continue with Google'),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
            ]),
          ),
        )),
      );
}
