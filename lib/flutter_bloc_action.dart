library flutter_bloc_action;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'
    hide BlocListenerBase, BlocListener;
import 'package:provider/single_child_widget.dart';

mixin BlocAction<Action, State> on BlocBase<State> {
  StreamController<Action>? __actionController;
  StreamController<Action> get _actionController {
    return __actionController ??= StreamController<Action>.broadcast();
  }

  Stream<Action> get action => _actionController.stream;

  void act(Action action) {
    if (_actionController.isClosed) return;
    _actionController.add(action);
  }

  @override
  Future<void> close() async {
    await super.close();
    await _actionController.close();
  }
}

typedef BlocActionWidgetListener<A> = void Function(
    BuildContext context, A action);

class BlocActionListener<B extends BlocAction<A, dynamic>, A>
    extends BlocActionListenerBase<B, A> {
  const BlocActionListener({
    Key? key,
    required BlocActionWidgetListener<A> listener,
    B? bloc,
    Widget? child,
  }) : super(
          key: key,
          child: child,
          listener: listener,
          bloc: bloc,
        );
}

abstract class BlocActionListenerBase<B extends BlocAction<A, dynamic>, A>
    extends SingleChildStatefulWidget {
  const BlocActionListenerBase({
    Key? key,
    required this.listener,
    this.bloc,
    this.child,
  }) : super(key: key, child: child);

  final Widget? child;

  final B? bloc;

  final BlocActionWidgetListener<A> listener;

  @override
  SingleChildState<BlocActionListenerBase<B, A>> createState() =>
      _BlocListenerBaseState<B, A>();
}

class _BlocListenerBaseState<B extends BlocAction<A, dynamic>, A>
    extends SingleChildState<BlocActionListenerBase<B, A>> {
  StreamSubscription<A>? _subscription;
  late B _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? context.read<B>();
    _subscribe();
  }

  @override
  void didUpdateWidget(BlocActionListenerBase<B, A> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldBloc = oldWidget.bloc ?? context.read<B>();
    final currentBloc = widget.bloc ?? oldBloc;
    if (oldBloc != currentBloc) {
      if (_subscription != null) {
        _unsubscribe();
        _bloc = currentBloc;
      }
      _subscribe();
    }
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) => child!;

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    _subscription = _bloc.action.listen((action) {
      widget.listener(context, action);
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }
}

