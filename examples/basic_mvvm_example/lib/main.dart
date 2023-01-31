

import 'package:flutter/material.dart' hide Action;
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';

import 'codebase/service.dart';
import 'codebase/view.dart';
import 'codebase/view_model.dart';

void main() {
  GetIt.I.registerSingleton<SharedCounter>(SharedCounter());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter MVVM Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainView(),
    );
  }
}

class MainView extends View<MainViewModel> {
  const MainView({
    super.key
  }) : super(create: MainViewModel.new);

  @override
  Widget build(BuildContext context) {
    final vm = $<MainViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          vm.number,
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          SubViewA(),
          SubViewB(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: vm.decrement,
        tooltip: 'Decrement',
        child: const Icon(Icons.remove),
      ),
    );
  }
}

class SubViewA extends View<ViewModelA> {
  const SubViewA({
    super.key
  }) : super(create: ViewModelA.new);

  @override
  Widget build(context) {
    print('build SubViewA');
    final vm = $<ViewModelA>(context);

    return Center(
      child: Column(
        children: [
          ElevatedButton(
            onPressed: vm.updateTime,
            child: Text('time update'),
          ),
          Text(
            vm.time,
          ),
          Text(
            vm.moneyInEuro,
          ),
        ],
      ),
    );
  }
}

class SubViewB extends View<ViewModelB> {
  const SubViewB({
    super.key
  }) : super(create: ViewModelB.new);

  @override
  Widget build(context) {
    print('build SubViewB');
    final vm = $<ViewModelB>(context);

    return Center(
      child: Column(
        children: [
          ElevatedButton(
            onPressed: vm.increment,
            child: Text('increment'),
          ),
          Test(),
        ],
      ),
    );
  }
}

class Test extends ViewFragment {
  @override
  Widget build(BuildContext context) {
    print('build ChildView');
    final vm = $<ViewModelB>(context);

    return Text(vm.number);
  }
}


//////////////////////////////////////


class MainViewModel extends ViewModel {
  SharedCounter get _repo => getService<SharedCounter>();

  late final decrement = Action(
    () => _repo.counter.value--,
  );

  String get number => _repo.counter.value.toString();
}


class ViewModelA extends ViewModel {
  SharedCounter get _repo => getService<SharedCounter>();

  set money(int newValue) => _repo.counter.value = newValue;

  String get moneyInEuro => '${_repo.counter.value} €';

  String get time => _repo.time.value.toString();

  late final updateTime = Action(
    () => _repo.time.value = DateTime.now(),
  );

}


class ViewModelB extends ViewModel {
  SharedCounter get _repo => getService<SharedCounter>();

  late final increment = Action(
    () => _repo.counter.value++,
  );

  String get number => _repo.counter.value.toString();
}


//////////////////////////////////////


class SharedCounter extends Service {
  final counter = Observable(0);

  final time = Observable(DateTime.now());
}
