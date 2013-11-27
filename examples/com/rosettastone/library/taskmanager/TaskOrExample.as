var initialTask:StubTask = new StubTask();
var fallbackTask:StubTask = new StubTask();

initialTask.or( fallbackTask ).run();