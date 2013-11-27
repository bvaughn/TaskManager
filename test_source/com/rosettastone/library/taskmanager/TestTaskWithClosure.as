package com.rosettastone.library.taskmanager {
	
	public class TestTaskWithClosure extends AbstractTaskTestCase {
		
		[Before]
		override public function setUp():void {
			super.setUp();
		}
		
		[After]
		override public function tearDown():void {
		}
		
		[Test]
		public function testAutoComplete():void {
			var executed:Boolean;
			
			var customRunFunction:Function =
				function():void {
					executed = true;
				};
			
			var taskWithClosure:TaskWithClosure =
				new TaskWithClosure(
					customRunFunction, true );
			
			addTaskEventListeners( taskWithClosure );
			
			assertFalse( executed );
			
			taskWithClosure.run();
			
			assertTrue( executed );
			
			assertNumEvents( 1, 0, 0 );
		}
		
		[Test]
		public function testAutoCompleteWithErrorDispatched():void {
			var customRunFunction:Function =
				function():void {
					taskWithClosure.errorTask();
				};
			
			var taskWithClosure:TaskWithClosure =
				new TaskWithClosure(
					customRunFunction, true );
			
			addTaskEventListeners( taskWithClosure );
			
			taskWithClosure.run();
			
			assertNumEvents( 0, 1, 0 );
		}
		
		[Test]
		public function testAutoCompleteWithErrorThrown():void {
			var customRunFunction:Function =
				function():void {
					throw new Error();
				};
			
			var taskWithClosure:TaskWithClosure =
				new TaskWithClosure(
					customRunFunction, true );
			
			addTaskEventListeners( taskWithClosure );
			
			taskWithClosure.run();
			
			assertNumEvents( 0, 1, 0 );
		}
		
		[Test]
		public function testWithoutAutoComplete():void {
			var customRunFunction:Function =
				function():void {
					// No-op
				};
			
			var taskWithClosure:TaskWithClosure =
				new TaskWithClosure(
					customRunFunction, false );
			
			addTaskEventListeners( taskWithClosure );
			
			taskWithClosure.run();
			
			assertNumEvents( 0, 0, 0 );
			
			taskWithClosure.finishTask();
			
			assertNumEvents( 1, 0, 0 );
		}
		
		[Test]
		public function testRuntimeErrorOccursInAsyncTask():void {
			var customRunFunction:Function =
				function():void {
					throw new Error();
				};
			
			var taskWithClosure:TaskWithClosure =
				new TaskWithClosure( customRunFunction );
			
			addTaskEventListeners( taskWithClosure );
			
			taskWithClosure.run();
			
			assertNumEvents( 0, 1, 0 );
		}
	}
}