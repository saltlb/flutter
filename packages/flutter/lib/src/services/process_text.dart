// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'dart:convert'; // Pour convertir la réponse en Map si nécessaire
import 'system_channels.dart';

/// A data structure describing text processing actions.
@immutable
class ProcessTextAction {
  /// Creates text processing actions based on those returned by the engine.
  const ProcessTextAction(this.id, this.label);

  /// The action unique id.
  final String id;

  /// The action localized label.
  final String label;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ProcessTextAction &&
      other.id == id &&
      other.label == label;
  }

  @override
  int get hashCode => Object.hash(id, label);
}

/// Determines how to interact with the text processing feature.
abstract class ProcessTextService {
  /// Returns a [Future] that resolves to a [List] of [ProcessTextAction]s
  /// containing all text processing actions available.
  ///
  /// If there are no actions available, an empty list will be returned.
  Future<List<ProcessTextAction>> queryTextActions();

  /// Returns a [Future] that resolves to a [String] when the text action
  /// returns a transformed text or null when the text action did not return
  /// a transformed text.
  ///
  /// The `id` parameter is the text action unique identifier returned by
  /// [queryTextActions].
  ///
  /// The `text` parameter is the text to be processed.
  ///
  /// The `readOnly` parameter indicates that the transformed text, if it exists,
  /// will be used as read-only.
  Future<String?> processTextAction(String id, String text, bool readOnly);
}

/// The service used by default for the text processing feature.
///
/// Any widget may use this service to get a list of text processing actions
/// and send requests to activate these text actions.
///
/// This is currently only supported on Android and it requires adding the
/// following '<queries>' element to the Android manifest file:
///
/// <manifest ...>
///     <application ...>
///       ...
///     </application>
///     <!-- Required to query activities that can process text, see:
///           https://developer.android.com/training/package-visibility?hl=en and
///           https://developer.android.com/reference/android/content/Intent#ACTION_PROCESS_TEXT.
///
///           In particular, this is used by the Flutter engine in io.flutter.plugin.text.ProcessTextPlugin. -->
///     <queries>
///         <intent>
///             <action android:name="android.intent.action.PROCESS_TEXT"/>
///             <data android:mimeType="text/plain"/>
///         </intent>
///     </queries>
/// </manifest>
///
/// The '<queries>' element is part of the Android manifest file generated when
/// running the 'flutter create' command.
///
/// If the '<queries>' element is not found, `queryTextActions()` will return an
/// empty list of `ProcessTextAction`.
///
/// See also:
///
///  * [ProcessTextService], the service that this implements.
class DefaultProcessTextService implements ProcessTextService {
  /// Creates the default service to interact with the platform text processing
  /// feature via communication over the text processing [MethodChannel].
  DefaultProcessTextService() {
    _processTextChannel = SystemChannels.processText;
  }

  /// The channel used to communicate with the engine side.
  late MethodChannel _processTextChannel;

  /// Set the [MethodChannel] used to communicate with the engine text processing
  /// feature.
  ///
  /// This is only meant for testing within the Flutter SDK.
  @visibleForTesting
  void setChannel(MethodChannel newChannel) {
    assert(() {
      _processTextChannel = newChannel;
      return true;
    }());
  }

  @override
  

Future<List<ProcessTextAction>> queryTextActions() async {
  final List<ProcessTextAction> textActions = <ProcessTextAction>[];

  try {
    final dynamic result = await _processTextChannel.invokeMethod(
      'ProcessText.queryTextActions',
    );

    // Vérifie si le résultat n'est pas null et est une Map
    if (result != null && result is Map<Object?, Object?>) {
      final Map<Object?, Object?> rawResults = result;

      // Traiter chaque élément dans la Map
      rawResults.forEach((key, value) {
        // Vérifie que la clé est une String et la valeur est une String
        if (key is String && value is String) {
          // Crée un ProcessTextAction et l'ajoute à la liste textActions
          textActions.add(ProcessTextAction(key, value));
        }
      });
    }
  } catch (e) {
    // En cas d'erreur, renvoie une liste vide
    print('Erreur lors de la récupération des actions de texte: $e');
  }

  return textActions;
}


  @override
  /// On Android, the readOnly parameter might be used by the targeted activity, see:
  /// https://developer.android.com/reference/android/content/Intent#EXTRA_PROCESS_TEXT_READONLY.
  Future<String?> processTextAction(String id, String text, bool readOnly) async {
    final String? processedText = await _processTextChannel.invokeMethod(
      'ProcessText.processTextAction',
      <dynamic>[id, text, readOnly],
    ) as String?;

    return processedText;
  }
}
