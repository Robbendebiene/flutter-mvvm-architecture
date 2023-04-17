import 'package:flutter/material.dart' hide Action;
import 'package:flutter_mvvm_architecture/flutter_mvvm_architecture.dart';
import 'package:mobx/mobx.dart';


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
  Widget build(context, viewModel) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          viewModel.number,
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
        onPressed: viewModel.decrement,
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
  Widget build(context, viewModel) {
    print('build SubViewA');
    return Center(
      child: Column(
        children: [
          ElevatedButton(
            onPressed: viewModel.updateTime,
            child: const Text('time update'),
          ),
          Text(
            viewModel.time,
          ),
          Text(
            viewModel.moneyInEuro,
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
  Widget build(context, viewModel) {
    print('build SubViewB');
    return Center(
      child: Column(
        children: [
          ElevatedButton(
            onPressed: viewModel.increment,
            child: Text('increment'),
          ),
          Test(),
        ],
      ),
    );
  }
}

class Test extends ViewFragment<ViewModelB> {
  @override
  Widget build(context, viewModel) {
    print('build ChildView');
    return Text(viewModel.number);
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
