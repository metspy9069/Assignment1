# High Performance Social Feed

## 1. Project Overview
The High Performance Social Feed is a production-grade Flutter application engineered to deliver a seamless, blazing-fast user experience. Designed with a heavy emphasis on front-end rendering performance, memory efficiency, and optimistic state management, this project serves as a technical showcase for modern mobile development practices using Flutter, Riverpod, and Supabase.

## 2. Architecture Diagram
```mermaid
graph TD
    A[UI Layer (FeedScreen & DetailScreen)] -->|Watches| B(FeedNotifier)
    B -->|Mutates| C{FeedState (Immutable)}
    B -->|Reads/Writes| D[FeedRepository]
    D -->|RPC & Queries| E[(Supabase PostgreSQL)]
    D -->|Downloads| F[Supabase Storage]
```

## 3. Riverpod State Flow
State management is handled via Riverpod's `NotifierProvider`. 
* **State Modeling**: State is encapsulated in an immutable `FeedState` class utilizing `Equatable`.
* **Unidirectional Flow**: The UI dispatches actions (e.g., `loadMorePosts()`) to the `FeedNotifier`. The notifier performs the logic, yields a new `FeedState` via `copyWith()`, and the UI reactively rebuilds.

## 4. Supabase Integration
Supabase serves as the backend-as-a-service, handling:
* **Storage**: Tiered image delivery (Raw, Mobile, Thumbnail).
* **Database**: `posts` table storing metadata and metrics.
* **RPC (Remote Procedure Call)**: The `toggle_like` function securely increments/decrements likes directly on the database to prevent race conditions from concurrent users.

## 5. Infinite Scroll Implementation
A `ScrollController` monitors the ListView. When the user scrolls past the 80% threshold (`currentScroll >= maxScroll * 0.8`), it triggers `loadMorePosts()`. The provider maintains an internal lock (`isLoading`) to prevent duplicate pagination requests, appending blocks of 10 items concurrently.

## 6. Optimistic Like Strategy
When a user likes a post, the `FeedNotifier` instantly updates the `isLiked` status and increments/decrements the `likeCount` locally. The UI re-renders synchronously, yielding 0ms perceived latency for the user, while the server synchronization happens entirely in the background.

## 7. Debounce Protection
To prevent users from spamming the backend by rapidly tapping the like button:
* A `Timer` debounce mechanism intercepts all taps for a specific `postId`.
* If tapped repeatedly, the local UI updates instantly, but the 500ms network timer resets.
* When the 500ms timer finally expires, the final state is evaluated against the original state, and *only* dispatches an RPC call if there was a net change.

## 8. Offline Revert Handling
If the debounced network request fails (due to a dropped connection or server error):
1. The `try-catch` block intercepts the failure.
2. The exact pre-optimistic state is securely pulled from an internal cache.
3. The specific post's `likeCount` and `isLiked` are rolled back.
4. A red `SnackBar` notifies the user of the failure seamlessly without a page reload.

## 9. Hero Animation Flow
When transitioning from the `FeedScreen` to the `DetailScreen`:
1. The thumbnail image utilizes a `Hero` widget tagged with `post.id`.
2. The `DetailScreen` receives the exact same tag, forcing the Flutter engine to animate the bounds smoothly between the two screens.
3. The `DetailScreen` immediately renders the cached thumbnail to avoid flickering, then asynchronously fetches the larger `mediaMobileUrl`, fading it in seamlessly via an `AnimatedOpacity`.

## 10. Performance Optimizations
* **Tiered Image Fetching**: Strict bandwidth conservation. Feeds strictly use low-res thumbnails. Details fetch medium-res. True high-res RAW images are completely deferred until the user explicitly requests a manual download via `Dio`.
* **Skeleton Loaders**: Custom `flutter_animate` shimmers replace generic spinners, preserving structural integrity during data fetching and preventing UI jumping.

## 11. Memory Optimizations
* **`RepaintBoundary`**: Applied to every `PostCard`. Prevents complex shadow geometry and clipped corners from being continually re-rasterized by the Skia/Impeller engine during high-velocity scrolling.
* **Dynamic `memCacheWidth`**: `CachedNetworkImage` scales the decoding footprint of images based precisely on the physical `devicePixelRatio`, strictly preventing the Dart VM from bleeding RAM on heavy feeds.

## 12. Screenshots Section
*(Placeholder: Insert your application screenshots here prior to final submission)*
* `Feed View Architecture`
* `Detail View Transitions`
* `Offline Error States`

## 13. Setup Instructions
1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Configure Supabase in `lib/core/constants/constants.dart`:
   ```dart
   class AppConstants {
     static const String supabaseUrl = 'YOUR_URL_HERE';
     static const String supabaseAnonKey = 'YOUR_KEY_HERE';
   }
   ```
3. Run the app:
   ```bash
   flutter run
   ```
