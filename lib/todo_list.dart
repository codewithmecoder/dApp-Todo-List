import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/todo_list_model.dart';

class TodoList extends StatelessWidget {
  const TodoList({super.key});

  @override
  Widget build(BuildContext context) {
    var listModel = Provider.of<TodoListModel>(context);
    TextEditingController textController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: const Text("TODOLIST"),
      ),
      body: listModel.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  flex: 4,
                  child: ListView.builder(
                    itemCount: listModel.taskCount,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(listModel.todos[index].taskName),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: TextField(
                          controller: textController,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: ElevatedButton(
                          onPressed: () {
                            listModel.addTask(textController.text);
                            textController.clear();
                          },
                          child: const Text("ADD"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
