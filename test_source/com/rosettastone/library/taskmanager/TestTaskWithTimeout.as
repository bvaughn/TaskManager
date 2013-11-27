package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.events.TaskEvent;
	
	public class TestTaskWithTimeout extends AbstractTaskTestCase {
		
		private var _decoratedTask:StubTask;
		private var _taskWithTimeout:TaskWithTimeout;
		
		[Before]
		override public function setUp():void {
			super.setUp();
			
			_decoratedTask = new StubTask();
			_taskWithTimeout = new TaskWithTimeout( _decoratedTask, 100 );
			
			addTaskEventListeners( _taskWithTimeout );
		}
		
		[After]
		override public function tearDown():void {
		}
		
		[Test]
		public function testTaskCompletesBeforeTimeOut():void {
			_taskWithTimeout.run();
			
			_decoratedTask.complete();
			
			assertFalse( _taskWithTimeout.running );
			assertTrue( _taskWithTimeout.isComplete );
			
			assertNumEvents( 1, 0, 0 );
		}
		
		[Test]
		public function testTaskDoesNotCompleteBeforeTimeOut():void {
			var handler:Function =
				function( event:TaskEvent ):void {
					assertNumEvents( 0, 1, 0 );
				};
			
			_taskWithTimeout.addEventListener(
				TaskEvent.ERROR,
				addAsync( handler, 250 ) );
			_taskWithTimeout.run();
		}
	}
}