// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

contract todoList{
    uint public taskCount;
    struct Task{
        string taskName;
        bool isComplete;
    }

    constructor() public {
        taskCount = 0;
    }

    mapping(uint => Task) public todos;

    event TaskCreated(string task, uint taskName);

    function createTask(string memory _taskName) public {
        // add task to mapping
        // increment taskCount
        todos[taskCount++] = Task(_taskName, false);
        // emit event
        emit TaskCreated(_taskName, taskCount - 1);
    }
}