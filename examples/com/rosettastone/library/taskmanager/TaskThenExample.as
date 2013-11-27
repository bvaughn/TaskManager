var firstTask:StubTask = new StubTask();
var secondTask:StubTask = new StubTask();

firstTask.then( secondTask ).run();