// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

class TodoListModel extends ChangeNotifier {
  List<Task> todos = [];
  bool isLoading = true;
  int taskCount = 0;
  final String _rpcUrl = "http://192.168.1.122:7545";
  final String _wsUrl = "ws://192.168.1.122:7545/";
  final String _privateKey =
      "7763908252b55f6ebe8b3648eb783853f60254e476cae6b5463e7070c04b1933";
  Credentials? _credentials;
  late Web3Client _web3Client;
  late String _abiCode;
  late EthereumAddress _contractAddress;
  late EthereumAddress _ownAddress;
  late DeployedContract _deployedContract;
  late ContractFunction _taskCount;
  late ContractFunction _todos;
  late ContractFunction _createTask;
  late ContractEvent _taskCreatedEvent;

  TodoListModel() {
    initialSetup();
  }

  Future<void> initialSetup() async {
    _web3Client = Web3Client(
      _rpcUrl,
      Client(),
      socketConnector: () {
        return IOWebSocketChannel.connect(_wsUrl).cast<String>();
      },
    );
    await getAbi();
    await getCredentials();
    await getDeployedContract();
  }

  Future<void> getAbi() async {
    String abiStringFile =
        await rootBundle.loadString("src/abis/todoList.json");

    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);
    _contractAddress =
        EthereumAddress.fromHex(jsonAbi["networks"]["5777"]["address"]);
  }

  Future<void> getCredentials() async {
    _credentials = EthPrivateKey.fromHex(_privateKey);
    _ownAddress = await _credentials!.extractAddress();
  }

  Future<void> getDeployedContract() async {
    _deployedContract = DeployedContract(
      ContractAbi.fromJson(_abiCode, "TodoList"),
      _contractAddress,
    );
    _taskCount = _deployedContract.function("taskCount");
    _createTask = _deployedContract.function("createTask");
    _todos = _deployedContract.function("todos");
    _taskCreatedEvent = _deployedContract.event("TaskCreated");
    getTodos();
  }

  getTodos() async {
    int totalTodo = ((await _web3Client.call(
            contract: _deployedContract,
            function: _taskCount,
            params: []))[0] as BigInt)
        .toInt();
    taskCount = totalTodo;
    todos.clear();
    for (var i = 0; i < totalTodo; i++) {
      var todo = await _web3Client.call(
          contract: _deployedContract,
          function: _todos,
          params: [BigInt.from(i)]);
      todos.add(
        Task(
          isCompleted: todo[1],
          taskName: todo[0],
        ),
      );
    }
    isLoading = false;
    notifyListeners();
  }

  addTask(String taskName) async {
    isLoading = true;
    notifyListeners();
    await _web3Client.sendTransaction(
      _credentials!,
      Transaction.callContract(
        contract: _deployedContract,
        function: _createTask,
        parameters: [taskName],
      ),
    );
    getTodos();
  }
}

class Task {
  String taskName;
  bool isCompleted;
  Task({
    required this.taskName,
    this.isCompleted = false,
  });

  Task copyWith({
    String? taskName,
    bool? isCompleted,
  }) {
    return Task(
      taskName: taskName ?? this.taskName,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'taskName': taskName,
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      taskName: map['taskName'] as String,
      isCompleted: map['isCompleted'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) =>
      Task.fromMap(json.decode(source) as Map<String, dynamic>);
}
