# Quick Spec: Fix Logout Redirect to Login Page

## Task
Fix the logout button so it immediately terminates the session and redirects the user to the login page, instead of leaving them on the home page.

## Root Cause
In `profile_screen.dart`, both logout buttons (desktop line 241, mobile line 560) call `ref.read(authServiceProvider).signOut()` without any explicit navigation. The router's `refreshListenable` + redirect logic *should* catch this since `/profile` is a protected route, but there's a race condition: after `signOut()` triggers `notifyListeners()`, the GoRouter re-evaluates and redirects from the protected `/profile` route — but it may land on `/` (home) instead of `/login` because `/` is not protected.

## Files to Modify
- `lib/features/profile/presentation/profile_screen.dart` — Update both logout button `onPressed` handlers (desktop: ~line 241, mobile: ~line 560) to explicitly `await signOut()` and then navigate to `/login`.

## Change Details
Replace both logout button handlers from:
```dart
onPressed: () => ref.read(authServiceProvider).signOut(),
```
To:
```dart
onPressed: () async {
  await ref.read(authServiceProvider).signOut();
  if (context.mounted) context.go('/login');
},
```

This ensures:
1. Session terminates immediately (`await signOut()` completes)
2. Explicit redirect to `/login` page happens after session cleanup
3. `context.mounted` check prevents navigation on a disposed widget

**Import needed:** `go_router` is likely already imported; verify `context.go` is available (from `package:go_router/go_router.dart`).

## Verification
- [ ] Click "Çıkış Yap" button on desktop layout → session ends, redirected to login page
- [ ] Click "Çıkış Yap" button on mobile layout → session ends, redirected to login page
- [ ] After logout, pressing browser back button does not return to profile
- [ ] No console errors or widget disposal warnings

## Notes
- The `signOut()` method in `auth_service.dart` already handles Firebase sign-out, clearing `_currentUser`, and calling `notifyListeners()` — no changes needed there.
- The router's redirect logic in `router.dart` already blocks unauthenticated users from protected routes — no changes needed there either.
- This is a single-file fix with two nearly identical changes.
- **Line numbers above are stale**: `profile_screen.dart` was heavily rewritten in the web-responsive redesign (spec 043-049, desktop sidebar layout added). Locate the logout `onPressed` handlers by searching for `signOut()` calls instead of trusting the line numbers.
