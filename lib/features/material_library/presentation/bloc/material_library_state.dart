import 'package:equatable/equatable.dart';
import 'package:flutter_core_project/features/material_library/domain/entities/material_library_item.dart';

enum MaterialLibraryStatus { initial, loading, success, failure }

class MaterialLibraryState extends Equatable {
  const MaterialLibraryState({
    this.status = MaterialLibraryStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  final MaterialLibraryStatus status;
  final List<MaterialLibraryItem> items;
  final String? errorMessage;

  MaterialLibraryState copyWith({
    MaterialLibraryStatus? status,
    List<MaterialLibraryItem>? items,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MaterialLibraryState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
