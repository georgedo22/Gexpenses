# ProGuard / R8 rules for the release build (isMinifyEnabled = true).
#
# Flutter's embedding and most first-party plugins already ship their own
# consumer rules inside their AARs, so only the exceptions live here.

# The plugin registrant is looked up by name when the engine starts.
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Flutter's deferred-components tooling references Play Core classes that
# are not bundled in a standard build.
-dontwarn com.google.android.play.core.**

# If a plugin ever breaks at runtime after minification, add a targeted keep
# rule for its package here instead of disabling minification, e.g.:
# -keep class com.example.plugin.** { *; }
