// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chatRepository)
final chatRepositoryProvider = ChatRepositoryProvider._();

final class ChatRepositoryProvider
    extends $FunctionalProvider<ChatRepository, ChatRepository, ChatRepository>
    with $Provider<ChatRepository> {
  ChatRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChatRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatRepository create(Ref ref) {
    return chatRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatRepository>(value),
    );
  }
}

String _$chatRepositoryHash() => r'ccf27dfe9c4ab01ba2db47ccaf7bccf319bc8adc';

@ProviderFor(imagePickerService)
final imagePickerServiceProvider = ImagePickerServiceProvider._();

final class ImagePickerServiceProvider
    extends
        $FunctionalProvider<
          ImagePickerService,
          ImagePickerService,
          ImagePickerService
        >
    with $Provider<ImagePickerService> {
  ImagePickerServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imagePickerServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imagePickerServiceHash();

  @$internal
  @override
  $ProviderElement<ImagePickerService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ImagePickerService create(Ref ref) {
    return imagePickerService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImagePickerService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImagePickerService>(value),
    );
  }
}

String _$imagePickerServiceHash() =>
    r'074eeb7f17e0494b932ed947a5838eada588509f';

/// Messaggi di oggi, sempre aggiornati: si ricarica a ogni cambiamento di
/// messaggi o reazioni (Realtime).

@ProviderFor(liveMessages)
final liveMessagesProvider = LiveMessagesProvider._();

/// Messaggi di oggi, sempre aggiornati: si ricarica a ogni cambiamento di
/// messaggi o reazioni (Realtime).

final class LiveMessagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChatMessage>>,
          List<ChatMessage>,
          Stream<List<ChatMessage>>
        >
    with
        $FutureModifier<List<ChatMessage>>,
        $StreamProvider<List<ChatMessage>> {
  /// Messaggi di oggi, sempre aggiornati: si ricarica a ogni cambiamento di
  /// messaggi o reazioni (Realtime).
  LiveMessagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveMessagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveMessagesHash();

  @$internal
  @override
  $StreamProviderElement<List<ChatMessage>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChatMessage>> create(Ref ref) {
    return liveMessages(ref);
  }
}

String _$liveMessagesHash() => r'c2579e5f6cdfc017b01f664bc0ec8e1b4f2a5e6f';

/// Link temporaneo dell'immagine di un messaggio (in cache finché la schermata vive).

@ProviderFor(chatImageUrl)
final chatImageUrlProvider = ChatImageUrlFamily._();

/// Link temporaneo dell'immagine di un messaggio (in cache finché la schermata vive).

final class ChatImageUrlProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Link temporaneo dell'immagine di un messaggio (in cache finché la schermata vive).
  ChatImageUrlProvider._({
    required ChatImageUrlFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatImageUrlProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatImageUrlHash();

  @override
  String toString() {
    return r'chatImageUrlProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return chatImageUrl(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatImageUrlProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatImageUrlHash() => r'a86ae2a4adf8ed4d738e242f436df3ca96e5ef6a';

/// Link temporaneo dell'immagine di un messaggio (in cache finché la schermata vive).

final class ChatImageUrlFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  ChatImageUrlFamily._()
    : super(
        retry: null,
        name: r'chatImageUrlProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Link temporaneo dell'immagine di un messaggio (in cache finché la schermata vive).

  ChatImageUrlProvider call(String path) =>
      ChatImageUrlProvider._(argument: path, from: this);

  @override
  String toString() => r'chatImageUrlProvider';
}

/// Azioni della chat. Ognuna dice se è andata a buon fine: la schermata ripristina
/// il testo e avvisa in caso contrario. keepAlive: terminano anche se la schermata
/// viene chiusa a metà.

@ProviderFor(ChatComposer)
final chatComposerProvider = ChatComposerProvider._();

/// Azioni della chat. Ognuna dice se è andata a buon fine: la schermata ripristina
/// il testo e avvisa in caso contrario. keepAlive: terminano anche se la schermata
/// viene chiusa a metà.
final class ChatComposerProvider extends $NotifierProvider<ChatComposer, void> {
  /// Azioni della chat. Ognuna dice se è andata a buon fine: la schermata ripristina
  /// il testo e avvisa in caso contrario. keepAlive: terminano anche se la schermata
  /// viene chiusa a metà.
  ChatComposerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatComposerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatComposerHash();

  @$internal
  @override
  ChatComposer create() => ChatComposer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$chatComposerHash() => r'67f02e9b176da735fde39473e1523647d255d494';

/// Azioni della chat. Ognuna dice se è andata a buon fine: la schermata ripristina
/// il testo e avvisa in caso contrario. keepAlive: terminano anche se la schermata
/// viene chiusa a metà.

abstract class _$ChatComposer extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
