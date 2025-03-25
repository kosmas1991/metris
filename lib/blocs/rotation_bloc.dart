import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class RotationEvent extends Equatable {
  const RotationEvent();

  @override
  List<Object> get props => [];
}

class ToggleRotationDirection extends RotationEvent {}

// State
class RotationState extends Equatable {
  final bool isClockwise;

  const RotationState({this.isClockwise = true});

  RotationState copyWith({bool? isClockwise}) {
    return RotationState(
      isClockwise: isClockwise ?? this.isClockwise,
    );
  }

  @override
  List<Object> get props => [isClockwise];
}

// Bloc
class RotationBloc extends HydratedBloc<RotationEvent, RotationState> {
  RotationBloc() : super(const RotationState()) {
    on<ToggleRotationDirection>(_onToggleRotationDirection);
  }

  void _onToggleRotationDirection(
    ToggleRotationDirection event,
    Emitter<RotationState> emit,
  ) {
    emit(state.copyWith(isClockwise: !state.isClockwise));
  }

  @override
  RotationState? fromJson(Map<String, dynamic> json) {
    return RotationState(
      isClockwise: json['isClockwise'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson(RotationState state) {
    return {
      'isClockwise': state.isClockwise,
    };
  }
}
