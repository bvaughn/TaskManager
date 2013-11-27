package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.events.TaskEvent;
	import com.rosettastone.library.taskmanager.events.TaskManagerEvent;
	
	import flash.events.ProgressEvent;
	
	import flexunit.framework.BetterTestCase;
	
	/**
	 * Tests basic functionality of the TaskManager component.
	 */
	public class TestTaskManager extends BetterTestCase {

		private var _taskManager:TaskManager;

		[Before]
		override public function setUp():void {
			super.setUp();

			_taskManager = new TaskManager();
		}

		[Test]
		public function testNoTasks():void {
			var allTasksComplete:Boolean;

			_taskManager.addEventListener( TaskManagerEvent.COMPLETE,
				function( event:TaskManagerEvent ):void {
				allTasksComplete = true;
			} );

			_taskManager.run();

			assertTrue( allTasksComplete );
			assertFalse( _taskManager.running );
		}

		[Test]
		public function testParallelTasks():void {
			var allTasksComplete:Boolean;

			var startedCountTask1:int = 0;
			var startedCountTask2:int = 0;
			var startedCountTask3:int = 0;

			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			var stubTask3:StubTask = new StubTask();

			stubTask1.addEventListener( TaskEvent.STARTED, function( event:TaskEvent ):void {
				startedCountTask1++;
			} );
			stubTask2.addEventListener( TaskEvent.STARTED, function( event:TaskEvent ):void {
				startedCountTask2++;
			} );
			stubTask3.addEventListener( TaskEvent.STARTED, function( event:TaskEvent ):void {
				startedCountTask3++;
			} );

			_taskManager.addEventListener( TaskManagerEvent.COMPLETE,
				function( event:TaskManagerEvent ):void {
				allTasksComplete = true;
			} );

			_taskManager.addTask( stubTask1 );
			_taskManager.addTask( stubTask2 );
			_taskManager.addTask( stubTask3 );
			_taskManager.run();

			assertFalse( allTasksComplete );
			assertTrue( stubTask1.running );
			assertTrue( stubTask2.running );
			assertTrue( stubTask3.running );
			assertTrue( _taskManager.running );

			stubTask1.complete();

			assertFalse( allTasksComplete );
			assertFalse( stubTask1.running );
			assertTrue( stubTask2.running );
			assertTrue( stubTask3.running );
			assertTrue( _taskManager.running );

			stubTask2.complete();

			assertFalse( allTasksComplete );
			assertFalse( stubTask1.running );
			assertFalse( stubTask2.running );
			assertTrue( stubTask3.running );
			assertTrue( _taskManager.running );

			stubTask3.complete();

			assertTrue( allTasksComplete );
			assertEquals( 1, startedCountTask1 );
			assertEquals( 1, startedCountTask2 );
			assertEquals( 1, startedCountTask3 );
			assertFalse( stubTask1.running );
			assertFalse( stubTask2.running );
			assertFalse( stubTask3.running );
			assertFalse( _taskManager.running );
		}

		[Test]
		public function testSerialTasks():void {
			var allTasksComplete:Boolean;

			var startedCountTask1:int = 0;
			var startedCountTask2:int = 0;
			var startedCountTask3:int = 0;

			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			var stubTask3:StubTask = new StubTask();

			stubTask1.addEventListener( TaskEvent.STARTED, function( event:TaskEvent ):void {
				startedCountTask1++;
			} );
			stubTask2.addEventListener( TaskEvent.STARTED, function( event:TaskEvent ):void {
				startedCountTask2++;
			} );
			stubTask3.addEventListener( TaskEvent.STARTED, function( event:TaskEvent ):void {
				startedCountTask3++;
			} );

			_taskManager.addEventListener( TaskManagerEvent.COMPLETE,
				function( event:TaskManagerEvent ):void {
				allTasksComplete = true;
			} );

			_taskManager.addTask( stubTask1 );
			_taskManager.addTask( stubTask2, [ stubTask1 ] );
			_taskManager.addTask( stubTask3, [ stubTask2 ] );
			_taskManager.run();

			assertFalse( allTasksComplete );
			assertEquals( 1, startedCountTask1 );
			assertEquals( 0, startedCountTask2 );
			assertEquals( 0, startedCountTask3 );
			assertTrue( stubTask1.running );
			assertFalse( stubTask2.running );
			assertFalse( stubTask3.running );
			assertTrue( _taskManager.running );

			stubTask1.complete();

			assertFalse( allTasksComplete );
			assertEquals( 1, startedCountTask1 );
			assertEquals( 1, startedCountTask2 );
			assertEquals( 0, startedCountTask3 );
			assertFalse( stubTask1.running );
			assertTrue( stubTask2.running );
			assertFalse( stubTask3.running );
			assertTrue( _taskManager.running );

			stubTask2.complete();

			assertFalse( allTasksComplete );
			assertEquals( 1, startedCountTask1 );
			assertEquals( 1, startedCountTask2 );
			assertEquals( 1, startedCountTask3 );
			assertFalse( stubTask1.running );
			assertFalse( stubTask2.running );
			assertTrue( stubTask3.running );
			assertTrue( _taskManager.running );

			stubTask3.complete();

			assertTrue( allTasksComplete );
			assertEquals( 1, startedCountTask1 );
			assertEquals( 1, startedCountTask2 );
			assertEquals( 1, startedCountTask3 );
			assertFalse( stubTask1.running );
			assertFalse( stubTask2.running );
			assertFalse( stubTask3.running );
			assertFalse( _taskManager.running );
		}

		[Test]
		public function testRedundantCompleteTaskEventsOnlyTrigger1TaskManagerEvent():void {
			var numCompleteTaskEvents:int = 0;
			var numCompleteTaskManagerEvents:int = 0;

			var stubTask1:StubTask = new StubTask();
			stubTask1.addEventListener( TaskEvent.COMPLETE, function( event:TaskEvent ):void {
				numCompleteTaskEvents++;
			} );

			_taskManager.addEventListener( TaskManagerEvent.COMPLETE,
				function( event:TaskManagerEvent ):void {
				numCompleteTaskManagerEvents++;
			} );

			_taskManager.addTask( stubTask1 );
			_taskManager.run();

			assertEquals( 0, numCompleteTaskEvents );
			assertEquals( 0, numCompleteTaskManagerEvents );

			stubTask1.complete();

			assertEquals( 1, numCompleteTaskEvents );
			assertEquals( 1, numCompleteTaskManagerEvents );

			stubTask1.complete();

			assertEquals( 1, numCompleteTaskEvents );
			assertEquals( 1, numCompleteTaskManagerEvents );
		}

		[Test]
		public function testRedundantErrorTaskEventsOnlyTrigger1TaskManagerEvent():void {
			var numErrorTaskEvents:int = 0;
			var numErrorTaskManagerEvents:int = 0;

			var stubTask1:StubTask = new StubTask();
			stubTask1.addEventListener( TaskEvent.ERROR, function( event:TaskEvent ):void {
				numErrorTaskEvents++;
			} );

			_taskManager.addEventListener( TaskManagerEvent.ERROR,
				function( event:TaskManagerEvent ):void {
				numErrorTaskManagerEvents++;
			} );

			_taskManager.addTask( stubTask1 );
			_taskManager.run();

			assertEquals( 0, numErrorTaskEvents );
			assertEquals( 0, numErrorTaskManagerEvents );

			stubTask1.error( "" );

			assertEquals( 1, numErrorTaskEvents );
			assertEquals( 1, numErrorTaskManagerEvents );

			stubTask1.error( "" );

			assertEquals( 1, numErrorTaskEvents );
			assertEquals( 1, numErrorTaskManagerEvents );
		}
		
		[Test]
		public function test_interruptInnerTaskWhileTaskManagerIsRunning_thenResumeInnerTask_taskManagerShouldCompleteWhenAllInnerTasksComplete():void {
			var innerTask1:InterruptibleStubTask = new InterruptibleStubTask();
			var innerTask2:InterruptibleStubTask = new InterruptibleStubTask();
			
			_taskManager = new TaskManager( true );
			_taskManager.addTask( innerTask1 );
			_taskManager.addTask( innerTask2 );
			_taskManager.run();
			
			assertTrue( innerTask1.isRunning, innerTask2.isRunning, _taskManager.isRunning );
			
			innerTask2.interrupt();
			
			assertTrue( innerTask2.isInterrupted );
			assertTrue( innerTask1.isRunning, _taskManager.isRunning );
			
			innerTask2.run();
			
			assertTrue( innerTask1.isRunning, innerTask2.isRunning, _taskManager.isRunning );
			
			innerTask1.complete();
			innerTask2.complete();
			
			assertTrue( innerTask1.isComplete, innerTask2.isComplete, _taskManager.isComplete );
		}
		
		[Test]
		public function test_interruptInnerTaskWhileTaskManagerIsRunning_thenInterruptTaskManager_thenRunTaskManager_doesInterruptedInnerTaskGetReRun():void {
			var innerTask1:InterruptibleStubTask = new InterruptibleStubTask();
			var innerTask2:InterruptibleStubTask = new InterruptibleStubTask();
			
			_taskManager = new TaskManager( true );
			_taskManager.addTask( innerTask1 );
			_taskManager.addTask( innerTask2 );
			_taskManager.run();
			
			assertTrue( innerTask1.isRunning, innerTask2.isRunning, _taskManager.isRunning );
			
			innerTask2.interrupt();
			
			assertTrue( innerTask2.isInterrupted );
			assertTrue( innerTask1.isRunning, _taskManager.isRunning );
			
			_taskManager.interrupt();
			
			assertTrue( innerTask1.isInterrupted, innerTask2.isInterrupted, _taskManager.isInterrupted );
			
			_taskManager.run();
			
			assertTrue( innerTask1.isRunning, innerTask2.isRunning, _taskManager.isRunning );
			
			innerTask1.complete();
			innerTask2.complete();
			
			assertTrue( innerTask1.isComplete, innerTask2.isComplete, _taskManager.isComplete );
		}
		
		[Test]
		public function testInterruptedInnerTasksDoNotTriggerTaskManagerInterruptedEvents():void {
			var numInterruptedTaskEvents:int = 0;
			var numInterruptedTaskManagerEvents:int = 0;
			
			var stubTask1:InterruptibleStubTask = new InterruptibleStubTask();
			stubTask1.addEventListener( TaskEvent.INTERRUPTED, function( event:TaskEvent ):void {
				numInterruptedTaskEvents++;
			} );
			
			_taskManager.addEventListener( TaskManagerEvent.INTERRUPTED,
				function( event:TaskManagerEvent ):void {
					numInterruptedTaskManagerEvents++;
				} );
			
			_taskManager.addTask( stubTask1 );
			_taskManager.run();
			
			assertEquals( 0, numInterruptedTaskEvents );
			assertEquals( 0, numInterruptedTaskManagerEvents );
			
			stubTask1.interrupt();
			
			assertEquals( 1, numInterruptedTaskEvents );
			assertEquals( 0, numInterruptedTaskManagerEvents );
		}

		[Test]
		public function testCyclicDependenciesSelfReference():void {
			var stubTask1:StubTask = new StubTask();

			var taskManager:TaskManager = new TaskManager();
			taskManager.addTask( stubTask1, [ stubTask1 ] );

			var errorCaught:Boolean = false;

			taskManager.addEventListener( TaskManagerEvent.ERROR,
				function( event:TaskManagerEvent ):void {
				errorCaught = true;
			} );
			taskManager.run();

			assertTrue( errorCaught );
		}

		[Test]
		public function testCyclicDependenciesMutualReference():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();

			var taskManager:TaskManager = new TaskManager();
			taskManager.addTask( stubTask1, [ stubTask2 ] );
			taskManager.addTask( stubTask2, [ stubTask1 ] );

			var errorCaught:Boolean = false;

			taskManager.addEventListener( TaskManagerEvent.ERROR,
				function( event:TaskManagerEvent ):void {
				errorCaught = true;
			} );
			taskManager.run();

			assertTrue( errorCaught );
		}

		[Test]
		public function testInvalidDependenciesDisconnectedReference():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();

			var taskManager:TaskManager = new TaskManager();
			taskManager.addTask( stubTask2, [ stubTask1 ] );

			var errorCaught:Boolean = false;

			taskManager.addEventListener( TaskManagerEvent.ERROR,
				function( event:TaskManagerEvent ):void {
				errorCaught = true;
			} );
			taskManager.run();

			assertTrue( errorCaught );
		}

		[Test]
		public function testInvalidJumbledUpDependencies():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			var stubTask3:StubTask = new StubTask();

			var taskManager:TaskManager = new TaskManager();
			taskManager.addTask( stubTask1 );
			taskManager.addTask( stubTask2, [ stubTask1, stubTask3 ] );
			taskManager.addTask( stubTask3, [ stubTask2 ] );

			var errorCaught:Boolean = false;

			taskManager.addEventListener( TaskManagerEvent.ERROR,
				function( event:TaskManagerEvent ):void {
				errorCaught = true;
			} );
			taskManager.run();

			assertTrue( errorCaught );
		}

		[Test]
		public function testNonCyclicButRedundantDependencies():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			var stubTask3:StubTask = new StubTask();

			var taskManager:TaskManager = new TaskManager();
			taskManager.addTask( stubTask1 );
			taskManager.addTask( stubTask2, [ stubTask1 ] );
			taskManager.addTask( stubTask3, [ stubTask1, stubTask2 ] );

			var errorCaught:Boolean = false;

			taskManager.addEventListener( TaskManagerEvent.ERROR,
				function( event:TaskManagerEvent ):void {
				errorCaught = true;
			} );
			taskManager.run();

			assertFalse( errorCaught );
		}
		
		[Test]
		public function testInterruptibleTask():void {
			var task:InterruptibleStubTask = new InterruptibleStubTask();
			var interruptedMessage:String = "";
			var interrupted:Boolean = false;
			var complete:Boolean = false;
			var errored:Boolean = false;
			task.addEventListener( TaskEvent.COMPLETE, function( event:TaskEvent ):void {
				complete = true;
			} );
			task.addEventListener( TaskEvent.ERROR, function( event:TaskEvent ):void {
				errored = true;
			} );
			task.addEventListener( TaskEvent.INTERRUPTED, function( event:TaskEvent ):void {
				interrupted = true;
				interruptedMessage = event.message;
			} );
			task.run();
			assertFalse( interrupted || errored || complete );
			
			task.interrupt();
			
			assertTrue( interrupted );
			assertFalse( errored || complete );
		}
		
		[Test]
		public function testTaskManagerSynchronous():void {
			_taskManager = new TaskManager();
			_taskManager.addTask( new Task() );
			
			assertFalse( _taskManager.synchronous );
			
			_taskManager = new TaskManager();
			_taskManager.addTask( new StubTask( true ) );
			
			assertTrue( _taskManager.synchronous );
		}
		
		// Tests pertaining to backwards compatibility
		
		[Test]
		public function testTaskManagerDispatchesBackwardsCompatibleCompleteEvent():void {
			var stubTask1:StubTask = new StubTask( true );
			var stubTask2:StubTask = new StubTask( true );
			
			var taskManagerEventCompleteDispatched:Boolean;
			
			_taskManager.addEventListener(
				TaskManagerEvent.COMPLETE,
				function( event:TaskManagerEvent ):void {
					taskManagerEventCompleteDispatched = true;
				} );
			
			_taskManager.addTask( stubTask1 );
			_taskManager.addTask( stubTask2 );
			_taskManager.run();
			
			assertTrue( taskManagerEventCompleteDispatched );
		}
		
		[Test]
		public function testTaskManagerDispatchesBackwardsCompatibleErrorEvent():void {
			var stubTask:StubTask = new StubTask();
			
			var taskManagerEventErrorDispatched:Boolean;
			
			_taskManager.addEventListener(
				TaskManagerEvent.ERROR,
				function( event:TaskManagerEvent ):void {
					taskManagerEventErrorDispatched = true;
				} );
			
			_taskManager.addTask( stubTask );
			_taskManager.run();
			
			stubTask.error();
			
			assertTrue( taskManagerEventErrorDispatched );
		}
		
		// Tests pertaining to adding/removing Tasks at runtime are below this line.
		
		[Test]
		public function testAddingTaskAtRuntimeWithoutDependencies():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			
			_taskManager.addTask( stubTask1 );
			_taskManager.run();
			
			assertTrue( stubTask1.running );
			assertFalse( stubTask2.running );
			
			_taskManager.addTask( stubTask2 );
			
			assertTrue( stubTask1.running );
			assertTrue( stubTask2.running );
			
			stubTask1.complete();
			
			assertFalse( _taskManager.completed );
			
			stubTask2.complete();
			
			assertTrue( _taskManager.completed );
		}
		
		[Test]
		public function testAddingTaskAtRuntimeWithDependencies():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			
			_taskManager.addTask( stubTask1 );
			_taskManager.run();
			
			assertTrue( stubTask1.running );
			assertFalse( stubTask2.running );
			
			_taskManager.addTask( stubTask2, [ stubTask1 ] );
			
			assertTrue( stubTask1.running );
			assertFalse( stubTask2.running );
			
			stubTask1.complete();
			
			assertFalse( _taskManager.completed );
			
			assertFalse( stubTask1.running );
			assertTrue( stubTask2.running );
			
			stubTask2.complete();
			
			assertTrue( _taskManager.completed );
		}
		
		[Test]
		public function testAddingTaskAtRuntimeWithInvalidDependencies():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			var stubTask3:StubTask = new StubTask();
			
			_taskManager.addTask( stubTask1 );
			_taskManager.run();
			
			var expectedErrorWasDispatched:Boolean = false;
			
			_taskManager.addEventListener(
				TaskManagerEvent.ERROR,
				function( event:TaskManagerEvent ):void {
					_taskManager.removeEventListener( TaskManagerEvent.ERROR, arguments.callee );
					
					expectedErrorWasDispatched = true;
				} );
			
			_taskManager.addTask( stubTask2, [ stubTask3 ] );
			
			assertTrue( expectedErrorWasDispatched );
		}
		
		[Test]
		public function testRemovingTaskAtRuntime():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			
			_taskManager.addTask( stubTask1 );
			_taskManager.addTask( stubTask2 );
			_taskManager.run();
			
			assertTrue( stubTask1.running );
			assertTrue( stubTask2.running );
			
			_taskManager.removeTask( stubTask2 );
			
			stubTask2.complete();
			
			assertFalse( _taskManager.completed );
			
			stubTask1.complete();
			
			assertTrue( _taskManager.completed );
		}
		
		[Test]
		public function testRemovingTaskAtRuntimeUpdatesDepdenciesAndExecutesPreviouslyBlockedTasks():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			
			_taskManager.addTask( stubTask1 );
			_taskManager.addTask( stubTask2, [ stubTask1 ] );
			_taskManager.run();
			
			assertTrue( stubTask1.running );
			assertFalse( stubTask2.running );
			
			_taskManager.removeTask( stubTask1 );
			
			assertFalse( _taskManager.completed );
			
			assertTrue( stubTask1.running );
			assertTrue( stubTask2.running );
			
			stubTask2.complete();
			
			assertTrue( _taskManager.completed );
		}
		
		[Test]
		public function testRemovingTaskAtRuntimeLeavingNoMoreRunningTasks():void {
			var stubTask1:StubTask = new StubTask();
			
			_taskManager.addTask( stubTask1 );
			_taskManager.run();
			
			assertTrue( stubTask1.running );
			
			_taskManager.removeTask( stubTask1 );
			
			assertTrue( _taskManager.completed );
		}
		
		// Tests pertaining to interruption
		
		[Test]
		public function testInterruptibleTaskManagerErrorsIfGivenNonInterruptibleChildTasksAsConstructorParam():void {
			var errorThrown:Boolean = false;
			
			try {
				_taskManager = new TaskManager( true );
				_taskManager.addTask( new Task() );
				
			} catch ( error:Error ) {
				errorThrown = true;
			}
			
			assertTrue( errorThrown );
		}
		
		[Test]
		public function testInterruptibleTaskManagerHandlesSynchronousChildTasks():void {
			var closure:Function =
				function():void {
					// No-op
				};
			
			_taskManager = new TaskManager( true );
			_taskManager.addTask(
				new TaskWithClosure( closure, true ) );
			_taskManager.run();
			
			assertFalse( _taskManager.running );
			assertTrue( _taskManager.completed );
		}
		
		[Test]
		public function testInterruptibleTaskManagerHandlesSimplePauseAndResume():void {
			var stubTask:InterruptibleStubTask = new InterruptibleStubTask();
			
			_taskManager = new TaskManager( true );
			_taskManager.addTask( stubTask );
			_taskManager.run();
			
			assertTrue( _taskManager.running );
			assertFalse( _taskManager.completed, _taskManager.isInterrupted );
			assertEquals( 1, stubTask.numTimesStarted );
			assertEquals( 0, stubTask.numTimesInterrupted, stubTask.numTimesCompleted );
			
			_taskManager.interrupt();
			
			assertFalse( _taskManager.running, _taskManager.completed );
			assertTrue( _taskManager.isInterrupted );
			assertEquals( 1, stubTask.numTimesStarted, stubTask.numTimesInterrupted );
			assertEquals( 0, stubTask.numTimesCompleted );
			
			_taskManager.run();
			
			stubTask.complete();
			
			assertFalse( _taskManager.running, _taskManager.isInterrupted );
			assertTrue( _taskManager.completed );
			assertEquals( 2, stubTask.numTimesStarted );
			assertEquals( 1, stubTask.numTimesInterrupted, stubTask.numTimesCompleted );
		}
		
		[Test]
		public function testInterruptibleTaskManagerHandlesPauseAndResumeWhenSomeTasksHaveCompleted():void {
			var stubTask1:InterruptibleStubTask = new InterruptibleStubTask();
			var stubTask2:InterruptibleStubTask = new InterruptibleStubTask();
			
			_taskManager = new TaskManager( true );
			_taskManager.addTask( stubTask1 );
			_taskManager.addTask( stubTask2 );
			_taskManager.run();
			
			stubTask1.complete();
			
			_taskManager.interrupt();
			
			assertFalse( _taskManager.running, _taskManager.completed );
			assertEquals( 1, stubTask1.numTimesStarted, stubTask2.numTimesStarted );
			assertTrue( stubTask1.isComplete );
			assertFalse( stubTask2.isComplete );
			
			_taskManager.run();
			
			stubTask2.complete();
			
			assertFalse( _taskManager.running );
			assertTrue( _taskManager.completed );
			assertEquals( 1, stubTask1.numTimesStarted );
			assertEquals( 2, stubTask2.numTimesStarted );
			assertTrue( stubTask1.isComplete );
			assertTrue( stubTask2.isComplete );
		}
		
		[Test]
		public function testInterruptibleTaskManagerHandlesPauseAndResumeTasksHaveDependencies():void {
			var stubTask1:InterruptibleStubTask = new InterruptibleStubTask();
			var stubTask2:InterruptibleStubTask = new InterruptibleStubTask();
			var stubTask3:InterruptibleStubTask = new InterruptibleStubTask();
			
			_taskManager = new TaskManager( true );
			_taskManager.addTask( stubTask1 );
			_taskManager.addTask( stubTask2, [ stubTask1 ] );
			_taskManager.addTask( stubTask3 );
			_taskManager.run();
			
			assertEquals( 1, stubTask1.numTimesStarted, stubTask3.numTimesStarted );
			assertEquals( 0, stubTask2.numTimesStarted );
			
			_taskManager.interrupt();
			
			assertEquals( 1, stubTask1.numTimesStarted, stubTask1.numTimesInterrupted, stubTask3.numTimesStarted, stubTask3.numTimesInterrupted );
			assertEquals( 0, stubTask2.numTimesStarted, stubTask2.numTimesInterrupted );
			
			_taskManager.run();
			
			assertEquals( 2, stubTask1.numTimesStarted, stubTask3.numTimesStarted );
			assertEquals( 0, stubTask2.numTimesStarted );
			
			stubTask1.complete();
			
			assertEquals( 2, stubTask1.numTimesStarted, stubTask3.numTimesStarted );
			assertEquals( 1, stubTask2.numTimesStarted, stubTask1.numTimesCompleted );
			
			stubTask2.complete();
			stubTask3.complete();
			
			assertEquals( 1, stubTask1.numTimesCompleted, stubTask2.numTimesCompleted, stubTask3.numTimesCompleted );
			assertTrue( _taskManager.isComplete );
		}
		
		// Tests pertaining to num-internal-operations
		
		[Test]
		public function testNumInternalOperationsSimple():void {
			_taskManager.addTask( new StubTask( true ) );
			_taskManager.addTask( new StubTask( true ) );
			
			assertEquals( 2, _taskManager.numInternalOperations, _taskManager.numInternalOperationsPending );
			assertEquals( 0, _taskManager.numInternalOperationsCompleted );
			
			_taskManager.run();
			
			assertEquals( 2, _taskManager.numInternalOperations, _taskManager.numInternalOperationsCompleted );
			assertEquals( 0, _taskManager.numInternalOperationsPending );
		}
		
		[Test]
		public function testNumInternalOperationsNested():void {
			_taskManager.addTask( new StubTask( true ) );
			_taskManager.addTask( new CompositeTask( [ new StubTask( true ), new StubTask( true ) ] ) );
			
			assertEquals( 3, _taskManager.numInternalOperations, _taskManager.numInternalOperationsPending );
			assertEquals( 0, _taskManager.numInternalOperationsCompleted );
			
			_taskManager.run();
			
			assertEquals( 3, _taskManager.numInternalOperations, _taskManager.numInternalOperationsCompleted );
			assertEquals( 0, _taskManager.numInternalOperationsPending );
		}
		
		[Test]
		public function testProgressEventsReflectTheCorrectNumberOfInternalOperations():void {
			_taskManager.addTask( new StubTask( true ) );
			_taskManager.addTask( new CompositeTask( [ new StubTask( true ), new StubTask( true ) ] ) );
			
			var numProgressEvents:int = 0;
			var allAssertionsPassed:Boolean = true;
			
			_taskManager.addEventListener(
				ProgressEvent.PROGRESS,
				function( event:ProgressEvent ):void {
					numProgressEvents++;
					
					if ( event.bytesLoaded != numProgressEvents && event.bytesTotal != 3 ) {
						allAssertionsPassed = false;
					}
				} );
			
			_taskManager.run();
			
			assertEquals( 3, numProgressEvents );
			assertTrue( allAssertionsPassed );
		}
		
		// Test resume after error
		
		[Test]
		public function test_resumeAfterError_serialTaskFlow():void {
			var innerTask1:StubTask = new StubTask();
			var innerTask2:StubTask = new StubTask();
			var innerTask3:StubTask = new StubTask();
			
			_taskManager = new TaskManager();
			_taskManager.addTask( innerTask1 );
			_taskManager.addTask( innerTask2, [ innerTask1 ] );
			_taskManager.addTask( innerTask3, [ innerTask2 ] );
			_taskManager.run();
			
			assertEquals( 1, innerTask1.numTimesStarted );
			assertEquals( 0, innerTask2.numTimesStarted, innerTask3.numTimesStarted );
			
			innerTask1.complete();
			
			assertEquals( 1, innerTask1.numTimesStarted, innerTask2.numTimesStarted );
			assertEquals( 0, innerTask3.numTimesStarted );
			
			innerTask2.error();
			
			assertTrue( _taskManager.isErrored );
			assertEquals( 1, innerTask1.numTimesCompleted );
			assertEquals( 1, innerTask2.numTimesErrored, _taskManager.numTimesErrored );
			assertEquals( 0, innerTask3.numTimesStarted );
			
			_taskManager.run();
			
			assertEquals( 1, innerTask1.numTimesStarted );
			assertEquals( 2, innerTask2.numTimesStarted );
			assertEquals( 0, innerTask3.numTimesStarted );
			
			innerTask2.complete();
			innerTask3.complete();
			
			assertTrue( _taskManager.isComplete );
			assertEquals( 1, innerTask1.numTimesStarted, innerTask1.numTimesCompleted );
			assertEquals( 2, innerTask2.numTimesStarted );
			assertEquals( 1, innerTask2.numTimesErrored, innerTask2.numTimesCompleted );
			assertEquals( 1, innerTask3.numTimesStarted, innerTask3.numTimesCompleted );
		}
		
		[Test]
		public function test_resumeAfterError_parallelTaskFlow():void {
			var innerTask1:StubTask = new StubTask();
			var innerTask2:StubTask = new StubTask();
			var innerTask3:StubTask = new StubTask();
			var innerTask4:StubTask = new StubTask();
			
			_taskManager = new TaskManager();
			_taskManager.addTask( innerTask1 );
			_taskManager.addTask( innerTask2 );
			_taskManager.addTask( innerTask3 );
			_taskManager.addTask( innerTask4 );
			
			assertEquals( 0, innerTask1.numTimesStarted, innerTask2.numTimesStarted, innerTask3.numTimesStarted, innerTask4.numTimesStarted );
			
			_taskManager.run();
			
			assertEquals( 1, innerTask1.numTimesStarted, innerTask2.numTimesStarted, innerTask3.numTimesStarted, innerTask4.numTimesStarted );
			
			innerTask2.error();
			
			assertTrue( _taskManager.running );	// Does not error until all inner-Tasks have errored.
			assertEquals( 0, _taskManager.numTimesErrored );
			assertEquals( 1, innerTask2.numTimesErrored );
			
			innerTask1.complete();
			innerTask3.complete();
			innerTask4.error();
			
			assertFalse( _taskManager.running );
			assertEquals( 1, innerTask2.numTimesErrored, innerTask4.numTimesErrored, _taskManager.numTimesErrored );
			assertEquals( 1, innerTask1.numTimesCompleted, innerTask3.numTimesCompleted );
			
			_taskManager.run();
			
			assertTrue( _taskManager.running );
			assertEquals( 1, innerTask1.numTimesStarted, innerTask3.numTimesStarted );	// Should not be restarted since they were previously completed.
			assertEquals( 2, innerTask2.numTimesStarted, innerTask4.numTimesStarted, _taskManager.numTimesStarted );
			
			innerTask2.complete();
			innerTask4.complete();
			
			assertFalse( _taskManager.running );
			assertEquals( 1, innerTask2.numTimesErrored, innerTask4.numTimesErrored, _taskManager.numTimesErrored );
			assertEquals( 1, innerTask1.numTimesCompleted, innerTask2.numTimesCompleted, innerTask3.numTimesCompleted, _taskManager.numTimesCompleted );
		}
		
		[Test]
		public function test_resumeAfterError_errorsBeforeTaskInterrupt_resumesAsExpectsByRetryingErroredTasks_parallelComposite():void {
			var stubTask1:InterruptibleStubTask = new InterruptibleStubTask();
			var stubTask2:InterruptibleStubTask = new InterruptibleStubTask();
			var stubTask3:InterruptibleStubTask = new InterruptibleStubTask();
			var stubTask4:InterruptibleStubTask = new InterruptibleStubTask();
			
			_taskManager = new TaskManager( true );
			_taskManager.addTask( stubTask1 );
			_taskManager.addTask( stubTask2 );
			_taskManager.addTask( stubTask3 );
			_taskManager.addTask( stubTask4 );
			_taskManager.run();
			
			assertEquals( 1, stubTask1.numTimesStarted, stubTask2.numTimesStarted, stubTask3.numTimesStarted, stubTask4.numTimesStarted );
			
			stubTask2.error();
			stubTask4.complete();
			
			assertTrue( _taskManager.running );
			
			_taskManager.interrupt();
			
			assertTrue( _taskManager.isInterrupted, stubTask1.isInterrupted, stubTask3.isInterrupted );
			
			_taskManager.run();
			
			assertEquals( 2, stubTask1.numTimesStarted, stubTask2.numTimesStarted, stubTask3.numTimesStarted );
			assertEquals( 1, stubTask4.numTimesStarted );
			
			stubTask1.complete();
			stubTask2.complete();
			stubTask3.complete();
			
			assertTrue( _taskManager.isComplete );
			assertEquals( 0, _taskManager.numTimesErrored );
			assertEquals( 1, _taskManager.numTimesCompleted );
		}
		
		[Test]
		public function test_erroredTaskPreventsSubsequentTasksFromExecuting_blockedTasksProperlyResumeWhenTaskManagerIsReRun():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			var stubTask3:StubTask = new StubTask();
			var stubTask4:StubTask = new StubTask();
			
			_taskManager = new TaskManager();
			_taskManager.addTask( stubTask1 );
			_taskManager.addTask( stubTask2 );
			_taskManager.addTask( stubTask3, [ stubTask2 ] );
			_taskManager.addTask( stubTask4 );
			_taskManager.run();
			
			assertTrue( _taskManager.isRunning, stubTask1.isRunning, stubTask2.isRunning, stubTask4.isRunning );
			assertFalse( stubTask3.isRunning );
			
			stubTask1.error();
			
			assertTrue( _taskManager.isRunning, stubTask2.isRunning, stubTask4.isRunning );
			assertFalse( stubTask1.isRunning, stubTask3.isRunning );
			
			stubTask2.complete();
			
			assertTrue( _taskManager.isRunning, stubTask4.isRunning );
			assertFalse( stubTask1.isRunning, stubTask2.isRunning, stubTask3.isRunning );
			
			stubTask4.complete();
			
			assertFalse( _taskManager.isRunning, stubTask1.isRunning, stubTask2.isRunning, stubTask3.isRunning, stubTask4.isRunning );
			
			_taskManager.run();
			
			assertTrue( _taskManager.isRunning, stubTask1.isRunning, stubTask3.isRunning );
			assertFalse( stubTask2.isRunning, stubTask4.isRunning );
			
			stubTask1.complete();
			stubTask3.complete();
			
			assertTrue( _taskManager.isComplete );
		}
		
		[Test]
		public function test_synchrnousTaskFailureFollowedBySynchronousTaskSuccess_taskManagerDoesNotRerunFailedSynchronousTask():void {
			var stubTask1:SynchronousStubTask = new SynchronousStubTask( true );  // Succeeds immediately
			var stubTask2:SynchronousStubTask = new SynchronousStubTask( false ); // Fails immediately
			var stubTask3:SynchronousStubTask = new SynchronousStubTask( true );  // Succeeds immediately
			var stubTask4:SynchronousStubTask = new SynchronousStubTask( true );  // Succeeds immediately
			
			_taskManager = new TaskManager();
			_taskManager.addTask( stubTask1 );
			_taskManager.addTask( stubTask2, [ stubTask1 ] );
			_taskManager.addTask( stubTask3, [ stubTask1 ] );
			_taskManager.addTask( stubTask4, [ stubTask3 ] );
			_taskManager.run();
			
			assertEquals( 1, stubTask1.numTimesStarted, stubTask2.numTimesStarted, stubTask3.numTimesStarted, stubTask4.numTimesStarted );
			
			assertTrue( _taskManager.isErrored, stubTask2.isErrored );
			assertTrue( stubTask1.isComplete, stubTask3.isComplete, stubTask4.isComplete );
		}
	}
}