# QA Testing Protocol

This document outlines the professional testing procedures for validating performance, state integrity, and edge case resilience within the application.

## 1. Infinite Scroll Test
* **Steps**: 
  1. Launch the app and wait for the initial skeleton loaders to resolve.
  2. Scroll rapidly downwards until the scrollbar reaches approximately 80% depth.
  3. Observe the bottom of the list interface.
* **Expected Result**: A circular loading indicator appears at the absolute bottom of the list. Exactly 10 new posts are seamlessly appended.
* **Pass Criteria**: The list extends without UI stuttering, jumping, or firing duplicate network requests for the same offset position.

## 2. Pull To Refresh Test
* **Steps**: 
  1. Scroll to the absolute top of the feed view.
  2. Pull down aggressively beyond the native physics boundary and release.
* **Expected Result**: The native `RefreshIndicator` appears. The feed resets gracefully to the first 10 posts.
* **Pass Criteria**: Existing posts remain fully visible while fetching the new batch (no sudden flashing to a blank screen), and the scroll position successfully resets.

## 3. Spam Click Test
* **Steps**: 
  1. Tap the "Like" (heart) button on a single post 10 times rapidly within 2 seconds.
  2. Stop tapping.
  3. Observe the UI and the Network Inspector logs.
* **Expected Result**: The UI toggles the heart instantly on every single tap. The network stays completely silent until exactly 500ms after the final tap.
* **Pass Criteria**: Exactly ONE (1) RPC request is dispatched to the backend, representing the final mathematically resolved state of the toggle session.

## 4. Offline Revert Test
* **Steps**: 
  1. Turn off Wi-Fi and Cellular Data on the physical device or emulator.
  2. Tap the "Like" button on an unliked post.
  3. Wait 500ms for the debounce timer to fire the pending network request.
* **Expected Result**: The heart initially turns red and the count increments synchronously. After 500ms, the heart reverts to empty, the count decrements back to origin, and a red failure `SnackBar` appears.
* **Pass Criteria**: The local UI state perfectly mirrors the failed server state without requiring a full page refresh.

## 5. Hero Animation Test
* **Steps**: 
  1. Tap on any post in the main feed.
  2. Tap the back button to return to the feed.
* **Expected Result**: The image smoothly expands from its list container directly into the detail view, and shrinks exactly back to its rigid bounds on exit.
* **Pass Criteria**: Zero flickering occurs during the transition. The thumbnail stays visible continuously while the high-resolution asset fades in asynchronously.

## 6. Memory Usage Test
* **Steps**: 
  1. Run the app in `profile` mode (`flutter run --profile`).
  2. Open the Flutter DevTools Memory tab.
  3. Scroll continuously until 100+ posts are actively loaded.
* **Expected Result**: The memory footprint increases linearly but severely plateaus as images fall out of the viewport cache.
* **Pass Criteria**: Total heap size remains rigidly stable and does not exceed device memory constraints, proving `memCacheWidth` successfully restricted raw pixel decoding.

## 7. Performance Test
* **Steps**: 
  1. Run the app in `profile` mode.
  2. Open the Flutter DevTools Performance timeline.
  3. Scroll up and down the feed aggressively.
* **Expected Result**: The UI frame build times stay strictly under 16ms (60 FPS target) or 8ms (120 FPS target).
* **Pass Criteria**: Zero dropped frames (jank) detected in the timeline tracking. The `RepaintBoundary` successfully isolates the complex cards from repainting the entire list unexpectedly.
