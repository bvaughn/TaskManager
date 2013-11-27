var initialTask:StubTask = new StubTask();
var parallelTask:StubTask = new StubTask();

initialTask.and( parallelTask ).run();