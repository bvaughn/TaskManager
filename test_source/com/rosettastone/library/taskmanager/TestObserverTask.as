package com.rosettastone.library.taskmanager {
	import flash.events.ProgressEvent;
	
	use namespace TaskPrivateNamespace;
	
	public class TestObserverTask extends AbstractTaskTestCase {
		
		private var _observerTask:ObserverTask;
		
		[Test]
		public function testFailUponErrorFalse():void {
			var stubTask:StubTask = new StubTask();
			
			_observerTask = new ObserverTask( [ stubTask ], false );
			
			addTaskEventListeners( _observerTask );
			
			_observerTask.run();
			
			var data:Object = new Object();
			
			stubTask.run();
			stubTask.error( "foobar", data );
			
			assertNumEvents( 1, 0, 0 );
			assertEquals( "", _message );
			assertEquals( null, _data );
		}
		
		[Test]
		public function testFailUponErrorTrue():void {
			var stubTask:StubTask = new StubTask();
			
			_observerTask = new ObserverTask( [ stubTask ], true );
			
			addTaskEventListeners( _observerTask );
			
			_observerTask.run();
			
			var data:Object = new Object();
			
			stubTask.run();
			stubTask.error( "foobar", data );
			
			assertNumEvents( 0, 1, 0 );
			assertEquals( "foobar", _message );
			assertEquals( data, _data );
		}
		
		[Test]
		public function testObserverWithNoTasksToObserve():void {
			_observerTask = new ObserverTask();
			
			addTaskEventListeners( _observerTask );
			
			_observerTask.run();
			
			assertNumEvents( 1, 0, 0 );
		}
		
		[Test]
		public function testObserverWithAllTasksCompletedBeforeRun():void {
			var stubTask:StubTask = new StubTask();
			stubTask.run();
			stubTask.complete();
			
			_observerTask = new ObserverTask( [ stubTask ] );
			
			addTaskEventListeners( _observerTask );
			
			_observerTask.run();
			
			assertNumEvents( 1, 0, 0 );
		}
		
		[Test]
		public function testTheObserverOnlyObservesAndDoesNotRunObservedTasks():void {
			var stubTask:StubTask = new StubTask();
			
			_observerTask = new ObserverTask( [ stubTask ] );
			_observerTask.run();
			
			assertFalse( stubTask.running );
		}
		
		[Test]
		public function testAddingNewTasksAtRuntime():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			
			_observerTask = new ObserverTask( [ stubTask1 ] );
			
			addTaskEventListeners( _observerTask );
			
			_observerTask.run();
			
			stubTask1.run();
			stubTask2.run();
			
			assertNumEvents( 0, 0, 0 );
			
			_observerTask.observeTask( stubTask2 );
			
			stubTask1.complete();
			
			assertNumEvents( 0, 0, 0 );
			
			stubTask2.complete();
			
			assertNumEvents( 1, 0, 0 );
		}
		
		[Test]
		public function testRemovingTasksAtRuntime():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			
			_observerTask = new ObserverTask( [ stubTask1, stubTask2 ] );
			
			addTaskEventListeners( _observerTask );
			
			_observerTask.run();
			
			stubTask1.run();
			stubTask2.run();
			
			assertNumEvents( 0, 0, 0 );
			
			_observerTask.stopObservingTask( stubTask2 );
			
			assertNumEvents( 0, 0, 0 );
			
			stubTask1.complete();
			
			assertNumEvents( 1, 0, 0 );
		}
		
		[Test]
		public function testRemovingTasksAtRuntimeLeavingOnlyCompletedTasks():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			
			_observerTask = new ObserverTask( [ stubTask1, stubTask2 ] );
			
			addTaskEventListeners( _observerTask );
			
			_observerTask.run();
			
			stubTask1.run();
			stubTask1.complete();
			
			stubTask2.run();
			
			assertNumEvents( 0, 0, 0 );
			
			_observerTask.stopObservingTask( stubTask2 );
			
			assertNumEvents( 1, 0, 0 );
		}
		
		[Test]
		public function testObserverWaitsUntilAllObservedTasksHaveCompleted():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			
			_observerTask = new ObserverTask( [ stubTask1, stubTask2 ] );
			
			addTaskEventListeners( _observerTask );
			
			_observerTask.run();
			
			stubTask1.run();
			stubTask2.run();
			
			stubTask1.complete();
			
			assertNumEvents( 0, 0, 0 );
			
			stubTask2.complete();
			
			assertNumEvents( 1, 0, 0 );
		}
		
		[Test]
		public function testAddingSameTaskMultipleTimesDoesNotBreakObserver():void {
			var stubTask1:StubTask = new StubTask();
			
			_observerTask = new ObserverTask( [ stubTask1, stubTask1 ] );
			
			addTaskEventListeners( _observerTask );
			
			_observerTask.run();
			
			stubTask1.run();
			
			assertNumEvents( 0, 0, 0 );
			
			_observerTask.observeTask( stubTask1 );
			
			stubTask1.complete();
			
			assertNumEvents( 1, 0, 0 );
		}
		
		// Tests pertaining to num-internal-operations
		
		[Test]
		public function testNumInternalOperationsSimple():void {
			_observerTask =
				new ObserverTask(
					[ new StubTask( true ),
					  new StubTask( true ) ] );
			
			assertEquals( 2, _observerTask.numInternalOperations, _observerTask.numInternalOperationsPending );
			assertEquals( 0, _observerTask.numInternalOperationsCompleted );
			
			_observerTask.run();
			
			// Remember, the ObserverTask does not execute its inner Tasks.
			for each ( var task:Task in _observerTask.observedTasks ) {
				task.run();
			}
			
			assertEquals( 2, _observerTask.numInternalOperations, _observerTask.numInternalOperationsCompleted );
			assertEquals( 0, _observerTask.numInternalOperationsPending );
		}
		
		[Test]
		public function testNumInternalOperationsNested():void {
			_observerTask =
				new ObserverTask(
					[ new StubTask( true ),
					  new CompositeTask( [ new StubTask( true ), new StubTask( true ) ] ) ] );
			
			assertEquals( 3, _observerTask.numInternalOperations, _observerTask.numInternalOperationsPending );
			assertEquals( 0, _observerTask.numInternalOperationsCompleted );
			
			_observerTask.run();
			
			// Remember, the ObserverTask does not execute its inner Tasks.
			for each ( var task:Task in _observerTask.observedTasks ) {
				task.run();
			}
			
			assertEquals( 3, _observerTask.numInternalOperations, _observerTask.numInternalOperationsCompleted );
			assertEquals( 0, _observerTask.numInternalOperationsPending );
		}
		
		[Test]
		public function testProgressEventsReflectTheCorrectNumberOfInternalOperations():void {
			_observerTask =
				new ObserverTask(
					[ new StubTask( true ),
					  new CompositeTask( [ new StubTask( true ), new StubTask( true ) ] ) ] );
			
			var numProgressEvents:int = 0;
			var allAssertionsPassed:Boolean = true;
			
			_observerTask.addEventListener(
				ProgressEvent.PROGRESS,
				function( event:ProgressEvent ):void {
					numProgressEvents++;
					
					if ( event.bytesLoaded != numProgressEvents && event.bytesTotal != 3 ) {
						allAssertionsPassed = false;
					}
				} );
			
			_observerTask.run();
			
			// Remember, the ObserverTask does not execute its inner Tasks.
			for each ( var task:Task in _observerTask.observedTasks ) {
				task.run();
			}
			
			assertEquals( 3, numProgressEvents );
			assertTrue( allAssertionsPassed );
		}
		
		// Test resume after error
		
		[Test]
		public function test_canBeRunAgainAfterInternalTaskErrors():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			
			_observerTask = new ObserverTask( [ stubTask1, stubTask2 ] );
			_observerTask.run();
			
			stubTask1.run();
			stubTask2.run();
			
			assertTrue( _observerTask.isRunning );
			
			stubTask1.error();
			
			assertTrue( _observerTask.isErrored );
			
			_observerTask.run();
			
			stubTask1.run();
			stubTask1.complete();
			
			assertTrue( _observerTask.isRunning );
			
			stubTask2.complete();
			
			assertTrue( _observerTask.isComplete );
		}
	}
}