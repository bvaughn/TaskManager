package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.events.TaskEvent;
	
	import flash.events.ProgressEvent;
	
	use namespace TaskPrivateNamespace;

	public class TestCompositeTask extends AbstractTaskTestCase {

		private var _compositeTask:CompositeTask;
		private var _taskManager:TaskManager;

		[Before]
		override public function setUp():void {
			super.setUp();
			
			_taskManager = new TaskManager();
			
			_compositeTask = new CompositeTask();
		}

		[Test]
		public function testEmptyTask():void {
			var taskComplete:Boolean = false;
			var taskErrored:Boolean = false;

			_compositeTask = new CompositeTask();
			_compositeTask.addEventListener( TaskEvent.COMPLETE, function( event:TaskEvent ):void {
				taskComplete = true;
			} );
			_compositeTask.addEventListener( TaskEvent.ERROR, function( event:TaskEvent ):void {
				taskErrored = true;
			} );

			_taskManager.addTask( _compositeTask );
			_taskManager.run();

			assertTrue( taskComplete );
			assertFalse( taskErrored );
		}

		[Test]
		public function testNormalParallelFlow():void {
			var taskComplete:Boolean = false;
			var taskErrored:Boolean = false;

			var innerTaskOne:StubTask = new StubTask();
			var innerTaskTwo:StubTask = new StubTask();
			var innerTaskThree:StubTask = new StubTask();

			_compositeTask = new CompositeTask( [ innerTaskOne, innerTaskTwo, innerTaskThree ] );
			_compositeTask.addEventListener( TaskEvent.COMPLETE, function( event:TaskEvent ):void {
				taskComplete = true;
			} );
			_compositeTask.addEventListener( TaskEvent.ERROR, function( event:TaskEvent ):void {
				taskErrored = true;
			} );

			assertFalse( innerTaskOne.running );
			assertFalse( innerTaskTwo.running );
			assertFalse( innerTaskThree.running );

			_taskManager.addTask( _compositeTask );
			_taskManager.run();

			assertTrue( innerTaskOne.running );
			assertTrue( innerTaskTwo.running );
			assertTrue( innerTaskThree.running );

			assertFalse( taskComplete );
			assertFalse( taskErrored );

			innerTaskOne.complete();

			assertFalse( innerTaskOne.running );
			assertTrue( innerTaskTwo.running );
			assertTrue( innerTaskThree.running );

			assertFalse( taskComplete );
			assertFalse( taskErrored );

			innerTaskTwo.complete();

			assertFalse( innerTaskOne.running );
			assertFalse( innerTaskTwo.running );
			assertTrue( innerTaskThree.running );

			assertFalse( taskComplete );
			assertFalse( taskErrored );

			innerTaskThree.complete();

			assertFalse( innerTaskOne.running );
			assertFalse( innerTaskTwo.running );
			assertFalse( innerTaskThree.running );

			assertTrue( taskComplete );
			assertFalse( taskErrored );
		}

		[Test]
		public function testErrorParallelFlow():void {
			var taskComplete:Boolean = false;
			var taskErrored:Boolean = false;
			var numTaskEvents:int = 0;
			
			var innerTaskOne:StubTask = new StubTask();
			var innerTaskTwo:StubTask = new StubTask();
			var innerTaskThree:StubTask = new StubTask();
			var innerTaskFour:StubTask = new StubTask();

			_compositeTask = new CompositeTask( [ innerTaskOne, innerTaskTwo, innerTaskThree, innerTaskFour ] );
			_compositeTask.addEventListener( TaskEvent.COMPLETE, function( event:TaskEvent ):void {
				taskComplete = true;
				
				numTaskEvents++;
			} );
			_compositeTask.addEventListener( TaskEvent.ERROR, function( event:TaskEvent ):void {
				taskErrored = true;
				
				numTaskEvents++;
			} );

			assertFalse( innerTaskOne.running );
			assertFalse( innerTaskTwo.running );
			assertFalse( innerTaskThree.running );
			assertFalse( innerTaskFour.running );

			_taskManager.addTask( _compositeTask );
			_taskManager.run();

			assertTrue( innerTaskOne.running );
			assertTrue( innerTaskTwo.running );
			assertTrue( innerTaskThree.running );
			assertTrue( innerTaskFour.running );

			assertFalse( taskComplete );
			assertFalse( taskErrored );
			assertEquals( 0, numTaskEvents );

			innerTaskOne.complete();

			assertFalse( innerTaskOne.running );
			assertTrue( innerTaskTwo.running );
			assertTrue( innerTaskThree.running );
			assertTrue( innerTaskFour.running );

			assertFalse( taskComplete );
			assertFalse( taskErrored );
			assertEquals( 0, numTaskEvents );

			innerTaskTwo.error( "error" );

			assertFalse( innerTaskOne.running );
			assertFalse( innerTaskTwo.running );
			assertTrue( innerTaskThree.running );
			assertTrue( innerTaskFour.running );
			
			assertFalse( taskComplete );
			assertFalse( taskErrored );
			assertEquals( 0, numTaskEvents );
			
			innerTaskThree.complete();
			innerTaskFour.error( "error" );
			
			assertFalse( innerTaskOne.running );
			assertFalse( innerTaskTwo.running );
			assertFalse( innerTaskThree.running );
			assertFalse( innerTaskFour.running );
			
			assertFalse( taskComplete );
			assertTrue( taskErrored );
			assertEquals( 1, numTaskEvents );
			assertEquals( 2, _compositeTask.erroredTasks.length );
			assertEquals( 1, _compositeTask.errorMessages.length );
		}

		[Test]
		public function testNormalSerialFlow():void {
			var numStartedTaskOneTaskEvents:int = 0;
			var numStartedTaskTwoTaskEvents:int = 0;
			var numStartedTaskThreeTaskEvents:int = 0;

			var numCompleteTaskOneTaskEvents:int = 0;
			var numCompleteTaskTwoTaskEvents:int = 0;
			var numCompleteTaskThreeTaskEvents:int = 0;

			var taskComplete:Boolean;

			var innerTaskOne:StubTask = new StubTask();
			innerTaskOne.addEventListener( TaskEvent.COMPLETE, function( event:TaskEvent ):void {
				numCompleteTaskOneTaskEvents++;
			} );
			innerTaskOne.addEventListener( TaskEvent.STARTED, function( event:TaskEvent ):void {
				numStartedTaskOneTaskEvents++;
			} );

			var innerTaskTwo:StubTask = new StubTask();
			innerTaskTwo.addEventListener( TaskEvent.COMPLETE, function( event:TaskEvent ):void {
				numCompleteTaskTwoTaskEvents++;
			} );
			innerTaskTwo.addEventListener( TaskEvent.STARTED, function( event:TaskEvent ):void {
				numStartedTaskTwoTaskEvents++;
			} );

			var innerTaskThree:StubTask = new StubTask();
			innerTaskThree.addEventListener( TaskEvent.COMPLETE, function( event:TaskEvent ):void {
				numCompleteTaskThreeTaskEvents++;
			} );
			innerTaskThree.addEventListener( TaskEvent.STARTED, function( event:TaskEvent ):void {
				numStartedTaskThreeTaskEvents++;
			} );

			_compositeTask = new CompositeTask( [ innerTaskOne, innerTaskTwo, innerTaskThree ],
				false );
			_compositeTask.addEventListener( TaskEvent.COMPLETE, function( event:TaskEvent ):void {
				taskComplete = true;
			} );

			assertFalse( innerTaskOne.running );
			assertFalse( innerTaskTwo.running );
			assertFalse( innerTaskThree.running );

			_taskManager.addTask( _compositeTask );
			_taskManager.run();

			assertEquals( 1, numStartedTaskOneTaskEvents );
			assertEquals( 0, numStartedTaskTwoTaskEvents );
			assertEquals( 0, numStartedTaskThreeTaskEvents );
			assertEquals( 0, numCompleteTaskOneTaskEvents );
			assertEquals( 0, numCompleteTaskTwoTaskEvents );
			assertEquals( 0, numCompleteTaskThreeTaskEvents );

			assertFalse( taskComplete );

			innerTaskOne.complete();

			assertEquals( 1, numStartedTaskOneTaskEvents );
			assertEquals( 1, numStartedTaskTwoTaskEvents );
			assertEquals( 0, numStartedTaskThreeTaskEvents );
			assertEquals( 1, numCompleteTaskOneTaskEvents );
			assertEquals( 0, numCompleteTaskTwoTaskEvents );
			assertEquals( 0, numCompleteTaskThreeTaskEvents );

			assertFalse( taskComplete );

			innerTaskTwo.complete();

			assertEquals( 1, numStartedTaskOneTaskEvents );
			assertEquals( 1, numStartedTaskTwoTaskEvents );
			assertEquals( 1, numStartedTaskThreeTaskEvents );
			assertEquals( 1, numCompleteTaskOneTaskEvents );
			assertEquals( 1, numCompleteTaskTwoTaskEvents );
			assertEquals( 0, numCompleteTaskThreeTaskEvents );

			assertFalse( taskComplete );

			innerTaskThree.complete();

			assertEquals( 1, numStartedTaskOneTaskEvents );
			assertEquals( 1, numStartedTaskTwoTaskEvents );
			assertEquals( 1, numStartedTaskThreeTaskEvents );
			assertEquals( 1, numCompleteTaskOneTaskEvents );
			assertEquals( 1, numCompleteTaskTwoTaskEvents );
			assertEquals( 1, numCompleteTaskThreeTaskEvents );

			assertTrue( taskComplete );
		}

		[Test]
		public function testErrorSerialFlow():void {
			var taskComplete:Boolean = false;
			var taskErrored:Boolean = false;

			var innerTaskTwoStarted:Boolean = false;

			var innerTaskOne:StubTask = new StubTask();
			var innerTaskTwo:StubTask = new StubTask();

			innerTaskTwo.addEventListener( TaskEvent.STARTED, function( event:TaskEvent ):void {
				innerTaskTwoStarted = true;
			} );

			_compositeTask = new CompositeTask( [ innerTaskOne, innerTaskTwo ], false );
			_compositeTask.addEventListener( TaskEvent.COMPLETE, function( event:TaskEvent ):void {
				taskComplete = true;
			} );
			_compositeTask.addEventListener( TaskEvent.ERROR, function( event:TaskEvent ):void {
				taskErrored = true;
			} );

			assertFalse( innerTaskOne.running );
			assertFalse( innerTaskTwo.running );

			_taskManager.addTask( _compositeTask );
			_taskManager.run();

			assertTrue( _taskManager.running );
			assertTrue( innerTaskOne.running );
			assertFalse( innerTaskTwo.running );

			assertFalse( taskComplete );
			assertFalse( taskErrored );

			innerTaskOne.error( "" );

			assertFalse( innerTaskOne.running );
			assertFalse( innerTaskTwo.running );

			assertFalse( taskComplete );
			assertTrue( taskErrored );

			assertFalse( _taskManager.running );
			assertFalse( innerTaskTwoStarted );
		}

		[Test]
		public function testInterruption():void {
			var numStartedTaskOneTaskEvents:int = 0;
			var numStartedTaskTwoTaskEvents:int = 0;
			var numStartedCompositeTaskEvents:int = 0;

			var numCompleteTaskOneTaskEvents:int = 0;
			var numCompleteTaskTwoTaskEvents:int = 0;
			var numCompleteCompositeTaskEvents:int = 0;

			var numInterruptedTaskOneTaskEvents:int = 0;
			var numInterruptedTaskTwoTaskEvents:int = 0;
			var numInterruptedCompositeTaskEvents:int = 0;

			var numErrorTaskOneTaskEvents:int = 0;
			var numErrorTaskTwoTaskEvents:int = 0;
			var numErrorCompositeTaskEvents:int = 0;

			var task1:InterruptibleStubTask = new InterruptibleStubTask();
			task1.addEventListener( TaskEvent.COMPLETE, function( event:TaskEvent ):void {
				numCompleteTaskOneTaskEvents++;
			} );
			task1.addEventListener( TaskEvent.ERROR, function( event:TaskEvent ):void {
				numErrorTaskOneTaskEvents++;
			} );
			task1.addEventListener( TaskEvent.INTERRUPTED, function( event:TaskEvent ):void {
				numInterruptedTaskOneTaskEvents++;
			} );
			task1.addEventListener( TaskEvent.STARTED, function( event:TaskEvent ):void {
				numStartedTaskOneTaskEvents++;
			} );
			var task2:InterruptibleStubTask = new InterruptibleStubTask();
			task2.addEventListener( TaskEvent.COMPLETE, function( event:TaskEvent ):void {
				numCompleteTaskTwoTaskEvents++;
			} );
			task2.addEventListener( TaskEvent.ERROR, function( event:TaskEvent ):void {
				numErrorTaskTwoTaskEvents++;
			} );
			task2.addEventListener( TaskEvent.INTERRUPTED, function( event:TaskEvent ):void {
				numInterruptedTaskTwoTaskEvents++;
			} );
			task2.addEventListener( TaskEvent.STARTED, function( event:TaskEvent ):void {
				numStartedTaskTwoTaskEvents++;
			} );

			var composite:CompositeTask = new CompositeTask( [ task1, task2 ], false );
			composite.addEventListener( TaskEvent.COMPLETE, function( event:TaskEvent ):void {
				numCompleteCompositeTaskEvents++;
			} );
			composite.addEventListener( TaskEvent.ERROR, function( event:TaskEvent ):void {
				numErrorCompositeTaskEvents++;
			} );
			composite.addEventListener( TaskEvent.INTERRUPTED, function( event:TaskEvent ):void {
				numInterruptedCompositeTaskEvents++;
			} );
			composite.addEventListener( TaskEvent.STARTED, function( event:TaskEvent ):void {
				numStartedCompositeTaskEvents++;
			} );
			assertEquals( 0, numStartedTaskOneTaskEvents );
			assertEquals( 0, numStartedTaskTwoTaskEvents );
			assertEquals( 0, numStartedCompositeTaskEvents );
			assertEquals( 0, numCompleteTaskOneTaskEvents );
			assertEquals( 0, numCompleteTaskTwoTaskEvents );
			assertEquals( 0, numCompleteCompositeTaskEvents );
			assertEquals( 0, numErrorTaskOneTaskEvents );
			assertEquals( 0, numErrorTaskTwoTaskEvents );
			assertEquals( 0, numErrorCompositeTaskEvents );
			assertEquals( 0, numInterruptedTaskOneTaskEvents );
			assertEquals( 0, numInterruptedTaskTwoTaskEvents );
			assertEquals( 0, numInterruptedCompositeTaskEvents );

			composite.run();
			assertEquals( 2, composite.pendingTasks.length );

			assertEquals( 1, numStartedTaskOneTaskEvents );
			assertEquals( 0, numStartedTaskTwoTaskEvents );
			assertEquals( 1, numStartedCompositeTaskEvents );
			assertEquals( 0, numCompleteTaskOneTaskEvents );
			assertEquals( 0, numCompleteTaskTwoTaskEvents );
			assertEquals( 0, numCompleteCompositeTaskEvents );
			assertEquals( 0, numErrorTaskOneTaskEvents );
			assertEquals( 0, numErrorTaskTwoTaskEvents );
			assertEquals( 0, numErrorCompositeTaskEvents );
			assertEquals( 0, numInterruptedTaskOneTaskEvents );
			assertEquals( 0, numInterruptedTaskTwoTaskEvents );
			assertEquals( 0, numInterruptedCompositeTaskEvents );

			composite.interrupt();
			
			assertTrue( task1.isInterrupted );
			assertEquals( 2, composite.pendingTasks.length );
			
			assertEquals( 1, numStartedTaskOneTaskEvents );
			assertEquals( 0, numStartedTaskTwoTaskEvents );
			assertEquals( 1, numStartedCompositeTaskEvents );
			assertEquals( 0, numCompleteTaskOneTaskEvents );
			assertEquals( 0, numCompleteTaskTwoTaskEvents );
			assertEquals( 0, numCompleteCompositeTaskEvents );
			assertEquals( 0, numErrorTaskOneTaskEvents );
			assertEquals( 0, numErrorTaskTwoTaskEvents );
			assertEquals( 0, numErrorCompositeTaskEvents );
			assertEquals( 1, numInterruptedTaskOneTaskEvents );
			assertEquals( 0, numInterruptedTaskTwoTaskEvents );
			assertEquals( 1, numInterruptedCompositeTaskEvents );
			
			assertEquals( 2, composite.pendingTasks.length );
		}
		
		[Test]
		public function testCompleteHandlerAndCompleteEventListenersInvokedBeforeNextTaskInSerialCompositeIsStarted():void {
			var stubTask1CompleteHandlerInvoked:Boolean;
			var stubTask1CompleteEventListenerInvoked:Boolean;
			var stubTask2CompleteHandlerAssertionsPassed:Boolean;
			var stubTask2CompleteEventListenerAssertionsPassed:Boolean;
			
			var stubTask1:StubTask = new StubTask();
			stubTask1.withCompleteHandler(
				function():void {
					stubTask1CompleteHandlerInvoked = true;
				} );
			stubTask1.addEventListener(
				TaskEvent.COMPLETE,
				function( event:TaskEvent ):void {
					stubTask1.removeEventListener( TaskEvent.COMPLETE, arguments.callee );
					
					stubTask1CompleteEventListenerInvoked = true;
				} );
			
			var stubTask2:StubTask = new StubTask();
			stubTask2.withStartedHandler(
				function():void {
					stubTask2CompleteHandlerAssertionsPassed = stubTask1CompleteHandlerInvoked && stubTask1CompleteEventListenerInvoked;
				} );
			stubTask2.addEventListener(
				TaskEvent.STARTED,
				function( event:TaskEvent ):void {
					stubTask1.removeEventListener( TaskEvent.STARTED, arguments.callee );
					
					stubTask2CompleteEventListenerAssertionsPassed = stubTask1CompleteHandlerInvoked && stubTask1CompleteEventListenerInvoked;
				} );
			
			_compositeTask = new CompositeTask( null, false );
			_compositeTask.addTask( stubTask1 );
			_compositeTask.addTask( stubTask2 );
			_compositeTask.run();
			
			stubTask1.complete();			
			stubTask2.complete();
			
			assertTrue( stubTask2CompleteEventListenerAssertionsPassed, stubTask2CompleteHandlerAssertionsPassed );
		}
		
		[Test]
		public function testCompositeTaskSynchronous():void {
			_compositeTask = new CompositeTask( [ new Task() ] );
			
			assertFalse( _compositeTask.synchronous );
			
			_compositeTask = new CompositeTask( [ new StubTask( true ) ] );
			
			assertTrue( _compositeTask.synchronous );
		}
		
		[Test]
		public function testCompletingSubTaskWhileCompositeInterruptedDoesNotTriggerNextSubTask():void {
			var stubTask1:InterruptibleStubTask = new InterruptibleStubTask();
			stubTask1.withCompleteHandler(
				function():void {
					_compositeTask.interrupt();
				} );
			
			var stubTask2:InterruptibleStubTask = new InterruptibleStubTask();
			
			_compositeTask = new CompositeTask( [ stubTask1, stubTask2 ], false );
			_compositeTask.run();
			
			stubTask1.complete();
			
			assertFalse( stubTask2.running, _compositeTask.running, _compositeTask.isComplete );
			assertTrue( _compositeTask.isInterrupted );
			
			_compositeTask.run();
			
			assertTrue( stubTask2.running );
			
			stubTask2.complete();
			
			assertTrue( _compositeTask.isComplete );
		}
		
		// Reset tests
		
		[Test]
		public function testResetComposite_noTasksInQueue():void {
			var errorThrown:Boolean = false;
			
			try {
				_compositeTask = new CompositeTask();
				_compositeTask.run();
				_compositeTask.reset();
				
			} catch ( error:Error ) {
				errorThrown = true;
			}
			
			assertFalse( errorThrown );
		}
		
		[Test]
		public function testResetComposite_serial():void {
			var stubTask1:InterruptibleStubTask = new InterruptibleStubTask();
			var stubTask2:InterruptibleStubTask = new InterruptibleStubTask();
			var stubTask3:InterruptibleStubTask = new InterruptibleStubTask();
			
			_compositeTask = new CompositeTask( [ stubTask1, stubTask2, stubTask3 ], false );
			_compositeTask.run();
			
			stubTask1.complete();
			
			_compositeTask.interrupt();
			
			assertEquals( 1, stubTask1.numTimesStarted, stubTask2.numTimesStarted );
			assertEquals( 0, stubTask3.numTimesStarted, stubTask1.numTimesReset, stubTask2.numTimesReset, stubTask3.numTimesReset );
			assertEquals( 1, _compositeTask.taskQueueIndex, _compositeTask.numCompletedTasks );
			assertEquals( 2, _compositeTask.numPendingTasks );
			assertEquals( 3, _compositeTask.numTasks );
			assertTrue( stubTask1.isComplete );
			
			_compositeTask.reset();
			
			assertEquals( 1, stubTask1.numTimesReset, stubTask2.numTimesReset );
			assertEquals( 0, stubTask3.numTimesReset );
			assertEquals( 0, _compositeTask.taskQueueIndex, _compositeTask.numCompletedTasks );
			assertEquals( 3, _compositeTask.numPendingTasks, _compositeTask.numTasks );
			assertFalse( stubTask1.isComplete );
			
			_compositeTask.run();
			
			assertEquals( 1, stubTask1.numTimesStarted );
			assertEquals( 0, stubTask2.numTimesStarted, stubTask3.numTimesStarted );
		}
		
		[Test]
		public function testResetComposite_parallel():void {
			var stubTask1:InterruptibleStubTask = new InterruptibleStubTask();
			var stubTask2:InterruptibleStubTask = new InterruptibleStubTask();
			
			_compositeTask = new CompositeTask( [ stubTask1, stubTask2 ], true );
			_compositeTask.run();
			
			stubTask1.complete();
			
			_compositeTask.interrupt();
			
			assertEquals( 1, stubTask1.numTimesStarted, stubTask2.numTimesStarted );
			assertEquals( 0, stubTask1.numTimesReset, stubTask2.numTimesReset );
			assertEquals( 1, _compositeTask.taskQueueIndex, _compositeTask.numCompletedTasks );
			assertEquals( 1, _compositeTask.numPendingTasks );
			assertEquals( 2, _compositeTask.numTasks );
			assertTrue( stubTask1.isComplete );
			
			_compositeTask.reset();
			
			assertEquals( 1, stubTask1.numTimesReset, stubTask2.numTimesReset );
			assertEquals( 0, _compositeTask.taskQueueIndex, _compositeTask.numCompletedTasks );
			assertEquals( 2, _compositeTask.numPendingTasks, _compositeTask.numTasks );
			assertFalse( stubTask1.isComplete );
			
			_compositeTask.run();
			
			assertEquals( 1, stubTask1.numTimesStarted, stubTask2.numTimesStarted );
		}
		
		[Test]
		public function testResetComposite_doesNotResetIfNotRun():void {
			var stubTask1:InterruptibleStubTask = new InterruptibleStubTask();
			var stubTask2:InterruptibleStubTask = new InterruptibleStubTask();
			
			_compositeTask = new CompositeTask( [ stubTask1, stubTask2 ], true );
			_compositeTask.reset();
			
			assertEquals( 0, _compositeTask.numTimesReset, stubTask1.numTimesReset, stubTask2.numTimesReset );
		}
		
		// Interruptibility tests
		
		[Test]
		public function testInterruptibleGetterReturnsTrueIfAllChildrenAreInterruptible():void {
			_compositeTask.addTask( new InterruptibleStubTask() );
			_compositeTask.addTask( new InterruptibleStubTask() );
			
			assertTrue( _compositeTask.interruptible );
		}
		
		[Test]
		public function testInterruptibleGetterReturnsTrueIfAllChildrenAreSynchronous():void {
			_compositeTask.addTask( new TaskWithClosure( null, true ) );
			_compositeTask.addTask( new TaskWithClosure( null, true ) );
			
			assertTrue( _compositeTask.interruptible );
		}
		
		[Test]
		public function testInterruptibleGetterReturnsFalseIfChildrenAreNotInterruptibleOrSynchronous():void {
			_compositeTask.addTask( new StubTask() );
			_compositeTask.addTask( new StubTask() );
			
			assertFalse( _compositeTask.interruptible );
		}
		
		// Tests pertaining to adding/removing Tasks at runtime are below this line.
		
		[Test]
		public function testAddingTaskToRunningParallelCompositeTask():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			
			_compositeTask = new CompositeTask( [ stubTask1 ], true );
			_compositeTask.run();
			
			assertTrue( stubTask1.running );
			assertFalse( stubTask2.running );
			
			_compositeTask.addTask( stubTask2 );
			
			assertTrue( stubTask1.running );
			assertTrue( stubTask2.running );
			
			stubTask1.complete();
			
			assertFalse( _compositeTask.isComplete );
			
			stubTask2.complete();
			
			assertTrue( _compositeTask.isComplete );
		}
		
		[Test]
		public function testAddingTaskToRunningSerialCompositeTask():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			
			_compositeTask = new CompositeTask( [ stubTask1 ], false );
			_compositeTask.run();
			
			assertTrue( stubTask1.running );
			assertFalse( stubTask2.running );
			
			_compositeTask.addTask( stubTask2 );
			
			assertTrue( stubTask1.running );
			assertFalse( stubTask2.running );
			
			stubTask1.complete();
			
			assertFalse( _compositeTask.isComplete );
			
			assertFalse( stubTask1.running );
			assertTrue( stubTask2.running );
			
			stubTask2.complete();
			
			assertTrue( _compositeTask.isComplete );
		}
		
		[Test]
		public function testErrorMessageAndDataBundlingInTheEventOfCompositeTaskFailure():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			var stubTask3:StubTask = new StubTask();
			
			_compositeTask = new CompositeTask( [ stubTask1, stubTask2, stubTask3 ] );
			_compositeTask.run();
			
			stubTask1.error( "foo", "string 1" );
			stubTask2.error( "foo", "string 2" );
			stubTask3.error( "bar", "string 3" );
			
			assertEquals( 3, _compositeTask.errorDatas.length );
			assertEquals( 2, _compositeTask.errorMessages.length );
			
			assertTrue( _compositeTask.errorMessages.indexOf( "foo" ) >= 0 );
			assertTrue( _compositeTask.errorMessages.indexOf( "bar" ) >= 0 );
			
			assertTrue( _compositeTask.errorDatas.indexOf( "string 1" ) >= 0 );
			assertTrue( _compositeTask.errorDatas.indexOf( "string 2" ) >= 0 );
			assertTrue( _compositeTask.errorDatas.indexOf( "string 3" ) >= 0 );
		}
		
		// Below this line are tests related to interruptForTask()
		
		[Test]
		public function testInterruptionForTaskWithInterruptingTaskComplete():void {
			addTaskEventListeners( _compositeTask );
			
			var task:InterruptibleStubTask = new InterruptibleStubTask();
			task.run();
			
			_compositeTask.addTask( task );
			_compositeTask.run();
			
			assertTrue( _compositeTask.running );
			assertTrue( task.running );
			
			var interruptingStubTask:StubTask = new StubTask();
			interruptingStubTask.run();
			
			_compositeTask.interruptForTask( interruptingStubTask );
			
			assertFalse( _compositeTask.running );
			assertFalse( task.running );
			
			interruptingStubTask.complete();
			
			assertTrue( _compositeTask.running );
			assertTrue( task.running );
			
			task.complete();
			
			assertNumEvents( 1, 0, 1 );
		}
		
		[Test]
		public function testInterruptionForTaskWithInterruptingTaskError():void {
			addTaskEventListeners( _compositeTask );
			
			var task:InterruptibleStubTask = new InterruptibleStubTask();
			
			_compositeTask.addTask( task );
			_compositeTask.run();
			
			assertTrue( _compositeTask.running );
			assertTrue( task.running );
			
			var interruptingStubTask:StubTask = new StubTask();
			interruptingStubTask.run();
			
			_compositeTask.interruptForTask( interruptingStubTask );
			
			assertFalse( _compositeTask.running );
			assertFalse( task.running );
			
			interruptingStubTask.error();
			
			assertNumEvents( 0, 1, 1 );
		}
		
		[Test]
		public function testInterruptionForTaskWithOverridingInterruptingTask():void {
			var task:InterruptibleStubTask = new InterruptibleStubTask();
			
			_compositeTask.addTask( task );
			_compositeTask.run();
			
			assertTrue( _compositeTask.running );
			assertTrue( task.running );
			
			var interruptingStubTask1:StubTask = new StubTask();
			interruptingStubTask1.run();
			var interruptingStubTask2:StubTask = new StubTask();
			interruptingStubTask2.run();
			
			_compositeTask.interruptForTask( interruptingStubTask1 );
			
			assertFalse( _compositeTask.running );
			assertFalse( task.running );
			
			_compositeTask.interruptForTask( interruptingStubTask2 );
			
			assertFalse( _compositeTask.running );
			assertFalse( task.running );
			
			interruptingStubTask1.complete();
			
			assertFalse( _compositeTask.running );
			assertFalse( task.running );
			
			interruptingStubTask2.complete();
			
			assertTrue( _compositeTask.running );
			assertTrue( task.running );
		}
		
		[Test]
		public function testInterruptionForTaskDoesNotStartNonRunningInterruptingTask():void {
			var task:InterruptibleStubTask = new InterruptibleStubTask();
			
			_compositeTask.addTask( task );
			_compositeTask.run();
			
			assertTrue( _compositeTask.running );
			assertTrue( task.running );
			
			var interruptingStubTask:StubTask = new StubTask();
			
			_compositeTask.interruptForTask( interruptingStubTask );
			
			assertFalse( interruptingStubTask.running );
			assertFalse( _compositeTask.running );
			assertFalse( _compositeTask.isComplete );
			
			interruptingStubTask.run();
			
			assertTrue( interruptingStubTask.running );
			assertFalse( _compositeTask.running );
			assertFalse( _compositeTask.isComplete );
			
			interruptingStubTask.complete();
			
			assertTrue( _compositeTask.running );
		}
		
		// Tests pertaining to Task removal
		
		[Test]
		public function testRemovingTaskBeforeRunning():void {
			for ( var index:int = 0; index < 2; index++ ) {
				var tasks:Array = [ new StubTask(), new StubTask() ];
				
				var taskToRemove:StubTask = tasks[ index ];
				var taskThatRemains:StubTask = tasks[ index == 0 ? 1 : 0 ];
				
				_compositeTask = new CompositeTask( tasks );
				_compositeTask.removeTask( taskToRemove );
				_compositeTask.run();
				
				assertFalse( taskToRemove.running );
				assertTrue( taskThatRemains.running );
				
				assertFalse( _compositeTask.isComplete );
				
				taskThatRemains.complete();
				
				assertTrue( _compositeTask.isComplete );
			}
		}
		
		[Test]
		public function testRemovingTaskAtRuntimeWhenTasksRunningInParallel():void {
			for ( var index:int = 0; index < 2; index++ ) {
				var tasks:Array = [ new StubTask(), new StubTask() ];
				
				var taskToRemove:StubTask = tasks[ index ];
				var taskThatRemains:StubTask = tasks[ index == 0 ? 1 : 0 ];
				
				_compositeTask = new CompositeTask( tasks );
				_compositeTask.run();
				
				assertTrue( taskToRemove.running, taskThatRemains.running );
				
				_compositeTask.removeTask( taskToRemove );
				
				assertFalse( _compositeTask.isComplete );
				
				taskToRemove.complete();
				
				assertFalse( _compositeTask.isComplete );
				
				taskThatRemains.complete();
				
				assertTrue( _compositeTask.isComplete );
			}
		}
		
		[Test]
		public function testRemovingAnInterruptedTaskAtRuntimeWhenTasksRunningInParallelDoesNotLeaveTheCompositeTaskHanging():void {
			var stubTask1:InterruptibleStubTask = new InterruptibleStubTask();
			var stubTask2:InterruptibleStubTask = new InterruptibleStubTask();
			var stubTask3:InterruptibleStubTask = new InterruptibleStubTask();
			
			_compositeTask = new CompositeTask( [ stubTask1, stubTask2, stubTask3 ], true );
			_compositeTask.run();
			
			assertEquals( 3, _compositeTask.numTasks );
			assertEquals( 0, _compositeTask.numCompletedTasks );
			assertEquals( 3, _compositeTask.numPendingTasks );
			
			stubTask2.complete();
			
			assertEquals( 3, _compositeTask.numTasks );
			assertEquals( 1, _compositeTask.numCompletedTasks );
			assertEquals( 2, _compositeTask.numPendingTasks );
			
			stubTask1.interrupt();
			
			_compositeTask.removeTask( stubTask1 );
			
			assertTrue( _compositeTask.running );
			assertEquals( 2, _compositeTask.numTasks );
			assertEquals( 1, _compositeTask.numCompletedTasks );
			assertEquals( 1, _compositeTask.numPendingTasks );
			
			stubTask3.complete();
			
			assertTrue( _compositeTask.isComplete );
		}
		
		[Test]
		public function testRemovingTaskAtRuntimeExecutesNextTaskIfInSequence():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			
			_compositeTask = new CompositeTask( [ stubTask1, stubTask2 ], false );
			_compositeTask.run();
			
			assertTrue( stubTask1.running );
			assertFalse( stubTask2.running );
			
			_compositeTask.removeTask( stubTask1 );
			
			assertTrue( stubTask2.running );
			assertFalse( _compositeTask.isComplete );
			
			stubTask2.complete();
			
			assertTrue( _compositeTask.isComplete );
		}
		
		[Test]
		public function testRemovingTaskAtRuntimeLeavingNoMoreRunningTasks():void {
			var stubTask1:StubTask = new StubTask();
			
			_compositeTask = new CompositeTask( [ stubTask1 ] );
			_compositeTask.run();
			
			assertTrue( stubTask1.running );
			
			_compositeTask.removeTask( stubTask1 );
			
			assertTrue( _compositeTask.isComplete );
		}
		
		[Test]
		public function testRemovingTaskMoreThanOnceDoesntInvalidateCompositeTask():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			
			_compositeTask = new CompositeTask( [ stubTask1, stubTask2 ], true );
			_compositeTask.run();
			
			assertEquals( 2, _compositeTask.numTasks );
			assertEquals( 0, _compositeTask.numCompletedTasks );
			assertEquals( 2, _compositeTask.numPendingTasks );
			
			for ( var index:int = 0; index < 2; index++ ) {
				_compositeTask.removeTask( stubTask1 );
				
				assertTrue( _compositeTask.running );
				
				assertEquals( 1, _compositeTask.numTasks );
				assertEquals( 0, _compositeTask.numCompletedTasks );
				assertEquals( 1, _compositeTask.numPendingTasks );
			}
			
			stubTask2.complete();
			
			assertTrue( _compositeTask.isComplete );
		}
		
		[Test]
		public function testRemovingTaskNotInTheCompositeShouldNotAffectComposite():void {
			for each ( var removedTaskShouldBeRunning:Boolean in [ true, false ] ) {
				for each ( var executeTasksInParallel:Boolean in [ true, false ] ) {
					var stubTask1:StubTask = new StubTask();
					var stubTask2:StubTask = new StubTask();
					var stubTask3:StubTask = new StubTask();
					
					var compositeTask:CompositeTask = new CompositeTask( [ stubTask1, stubTask2 ], executeTasksInParallel );
					compositeTask.run();
					
					var index:int = compositeTask.taskQueueIndex;
					
					if ( executeTasksInParallel ) {
						assertEquals( 1, stubTask1.numTimesStarted, stubTask2.numTimesStarted );
					} else {
						assertEquals( 1, stubTask1.numTimesStarted );
						assertEquals( 0, stubTask2.numTimesStarted );
					}
					
					assertFalse( compositeTask.isComplete );
					
					if ( removedTaskShouldBeRunning ) {
						stubTask3.run();
					}
					
					compositeTask.removeTask( stubTask3 );
					
					if ( executeTasksInParallel ) {
						assertEquals( 1, stubTask1.numTimesStarted, stubTask2.numTimesStarted );
					} else {
						assertEquals( 1, stubTask1.numTimesStarted );
						assertEquals( 0, stubTask2.numTimesStarted );
					}
					
					assertEquals( index, compositeTask.taskQueueIndex );
					assertFalse( compositeTask.isComplete );
					
					stubTask1.complete();
					stubTask2.complete();
					
					assertTrue( compositeTask.isComplete );
				}
			}
		}
		
		/*
		 * Tests pertaining to addMultiple() and removeMultiple() convenience methods
		 */
		
		[Test]
		public function testAddMultipleTasksAndFunctions():void {
			var stubTask1:StubTask = new StubTask( true );
			var stubTask2:StubTask = new StubTask( true );
			
			_compositeTask.addMultiple(
				functionOne, stubTask1, functionTwo, stubTask2 );
			
			assertEquals( 4, _compositeTask.numTasks, _compositeTask.numPendingTasks );
			
			_compositeTask.run();
			
			assertTrue( stubTask1.isComplete, stubTask2.isComplete, _functionOneInvoked, _functionTwoInvoked );
		}
		
		[Test]
		public function testAddMultipleTasksAndFunctionsThrowsError():void {
			var errorThrown:Boolean;
			
			try {
				_compositeTask.addMultiple( new Object() );
				
			} catch ( error:Error ) {
				errorThrown = true;
			}
			
			assertTrue( errorThrown );
		}
		
		[Test]
		public function testRemoveMultipleTasksAndFunctions():void {
			var stubTask1:StubTask = new StubTask( true );
			var stubTask2:StubTask = new StubTask( true );
			
			_compositeTask.addMultiple(
				functionOne, stubTask1, functionTwo, stubTask2 );
			
			assertEquals( 4, _compositeTask.numTasks, _compositeTask.numPendingTasks );
			
			_compositeTask.removeMultiple(
				stubTask1, functionTwo );
			
			assertEquals( 2, _compositeTask.numTasks, _compositeTask.numPendingTasks );
			
			_compositeTask.run();
			
			assertTrue( stubTask2.isComplete, _functionOneInvoked );
			assertFalse( stubTask1.isComplete, _functionTwoInvoked );
		}
		
		[Test]
		public function testRemoveMultipleTasksAndFunctionsThrowsError():void {
			var errorThrown:Boolean;
			
			try {
				_compositeTask.removeMultiple( new Object() );
				
			} catch ( error:Error ) {
				errorThrown = true;
			}
			
			assertTrue( errorThrown );
		}
		
		/*
		 * Tests pertaining to individualTaskComplete
		 */
		
		[Test]
		public function testProgresseEventsAreDispatched():void {
			for each ( var executeTasksInParallel:Boolean in [ true, false ] ) {
				var stubTask1:StubTask = new StubTask();
				var stubTask2:StubTask = new StubTask();
				var stubTask3:StubTask = new StubTask();
				
				var allAssertionsPassed:Boolean = true;
				var numProgressEvents:int = 0;
				
				var progressEventHandler:Function =
					function( event:ProgressEvent ):void {
						numProgressEvents++;
						
						if ( event.bytesLoaded != numProgressEvents ||
						     event.bytesTotal != 3 ) {
							
							allAssertionsPassed = false;
						}
					};
				
				_compositeTask = new CompositeTask( [ stubTask1, stubTask2, stubTask3 ], executeTasksInParallel );
				_compositeTask.addEventListener( ProgressEvent.PROGRESS, progressEventHandler );
				_compositeTask.run();
				
				assertEquals( 0, numProgressEvents );
				
				stubTask1.complete();
				
				assertEquals( 1, numProgressEvents );
				
				stubTask2.complete();
				
				assertEquals( 2, numProgressEvents );
				
				stubTask3.complete();
				
				assertEquals( 3, numProgressEvents );
				
				assertTrue( allAssertionsPassed );
			}
		}
		
		[Test]
		public function testIndividualTaskCompleteCalledUponTaskCompletion():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			
			var compositeTaskSubClass:CompositeTaskSubClass =
				new CompositeTaskSubClass(
					[ stubTask1, stubTask2 ], false );
			compositeTaskSubClass.run();
			
			assertEquals( 0, compositeTaskSubClass.individualTasksCompleted.length );
			
			stubTask1.complete();
			
			assertEquals( 1, compositeTaskSubClass.individualTasksCompleted.length );
			
			stubTask2.complete();
			
			assertTrue( compositeTaskSubClass.isComplete );
			assertEquals( 2, compositeTaskSubClass.individualTasksCompleted.length );
		}
		
		[Test]
		public function testIndividualTaskCompleteNotCalledWhenTaskRemoved():void {
			var stubTask1:StubTask = new StubTask();
			
			var compositeTaskSubClass:CompositeTaskSubClass =
				new CompositeTaskSubClass(
					[ stubTask1 ], false );
			compositeTaskSubClass.run();
			
			assertEquals( 0, compositeTaskSubClass.individualTasksCompleted.length );
			
			compositeTaskSubClass.removeTask( stubTask1 );
			
			assertTrue( compositeTaskSubClass.isComplete );
			assertEquals( 0, compositeTaskSubClass.individualTasksCompleted.length );
		}
		
		[Test]
		public function testAddTasksBeforeRunDoesNotAutoStartTasksUntilAllTasksHaveBeenAdded():void {
			new StubCompositeTaskThatAddsStubTasksBeforeRun().run();
		}
		
		/*
		 * Test add/remove function
		 */
		
		private var _functionOneInvoked:Boolean;
		private var _functionTwoInvoked:Boolean;
		
		private function functionOne():void {
			_functionOneInvoked = true;
		}
		
		private function functionTwo():void {
			_functionTwoInvoked = true;
		}
		
		[Test]
		public function testNonTaskOrFunctionConstructorArg():void {
			var errorThrown:Boolean;
			
			try {
				var compositeTask:CompositeTask =
					new CompositeTask( [ new Object() ] );
				
			} catch ( error:Error ) {
				errorThrown = true;
			}
			
			assertTrue( errorThrown );
		}
		
		[Test]
		public function testFunctionsAsConstructorArgs():void {
			var compositeTask:CompositeTask =
				new CompositeTask( [ functionOne, functionTwo ] );
			
			assertEquals( 2, compositeTask.numTasks );
		}
		
		[Test]
		public function testAddFunction():void {
			var compositeTask:CompositeTask = new CompositeTask();
			compositeTask.addFunction( functionOne );
			
			addTaskEventListeners( compositeTask );
			
			compositeTask.run();
			
			assertTrue( _functionOneInvoked );
			assertNumEvents( 1, 0, 0 );
		}
		
		[Test]
		public function testRemoveFunction():void {
			var compositeTask:CompositeTask = new CompositeTask();
			
			var taskWithClosureOne:TaskWithClosure =
				compositeTask.addFunction( functionOne );
			var taskWithClosureTwo:TaskWithClosure =
				compositeTask.addFunction( functionTwo );
			
			assertNotNull( taskWithClosureOne, taskWithClosureTwo );
			
			var returnedTaskWithClosureOne:TaskWithClosure =
				compositeTask.removeFunction( functionOne );
			
			assertTrue( taskWithClosureOne === returnedTaskWithClosureOne );
			
			compositeTask.run();
			
			assertTrue( _functionTwoInvoked );
			assertFalse( _functionOneInvoked );
		}
		
		/*
		 * Misc reported defects and other tests
		 */
		
		[Test]
		public function testAddTasksBeforeRunOnlyResultsInTasksBeingExecutedOnceWithOnlyOneSubTask():void {
			for each ( var executedTasksInParallel:Boolean in [ true, false ] ) {
				var stubTask1NumStartedEvents:int = 0;
				
				var compositeTaskContainingOneStubTasks:CompositeTaskContainingOneStubTasks =
					new CompositeTaskContainingOneStubTasks( executedTasksInParallel );
				compositeTaskContainingOneStubTasks.stubTask1.withStartedHandler(
					function():void {
						stubTask1NumStartedEvents++;
					} );
				compositeTaskContainingOneStubTasks.run();
				
				assertEquals( 1, stubTask1NumStartedEvents );
				
				// Running the CompositeTask a 2nd time should not re-run any of hte contained Tasks, since they've already been run (and completed).
				compositeTaskContainingOneStubTasks.run();
				
				assertEquals( 1, stubTask1NumStartedEvents );
			}
		}
		
		[Test]
		public function testAddTasksBeforeRunOnlyResultsInTasksBeingExecutedOnce():void {
			for each ( var executedTasksInParallel:Boolean in [ true, false ] ) {
				var stubTask1NumStartedEvents:int = 0;
				var stubTask2NumStartedEvents:int = 0;
				var stubTask3NumStartedEvents:int = 0;
				
				var compositeTaskContainingThreeStubTasks:CompositeTaskContainingThreeStubTasks =
					new CompositeTaskContainingThreeStubTasks( executedTasksInParallel );
				compositeTaskContainingThreeStubTasks.stubTask1.withStartedHandler(
					function():void {
						stubTask1NumStartedEvents++;
					} );
				compositeTaskContainingThreeStubTasks.stubTask2.withStartedHandler(
					function():void {
						stubTask2NumStartedEvents++;
					} );
				compositeTaskContainingThreeStubTasks.stubTask3.withStartedHandler(
					function():void {
						stubTask3NumStartedEvents++;
					} );
				compositeTaskContainingThreeStubTasks.run();
				
				assertEquals( 1, stubTask1NumStartedEvents, stubTask2NumStartedEvents, stubTask3NumStartedEvents );
				
				// Running the CompositeTask a 2nd time should not re-run any of hte contained Tasks, since they've already been run (and completed).
				compositeTaskContainingThreeStubTasks.run();
				
				assertEquals( 1, stubTask1NumStartedEvents, stubTask2NumStartedEvents, stubTask3NumStartedEvents );
			}
		}
		
		// Tests pertaining to num-internal-operations
		
		[Test]
		public function testNumInternalOperationsSimple():void {
			_compositeTask.addMultiple(
				new StubTask( true ),
				function():void {},
				new StubTask( true ) );
			
			assertEquals( 3, _compositeTask.numInternalOperations, _compositeTask.numInternalOperationsPending );
			assertEquals( 0, _compositeTask.numInternalOperationsCompleted );
			
			_compositeTask.run();
			
			assertEquals( 3, _compositeTask.numInternalOperations, _compositeTask.numInternalOperationsCompleted, _compositeTask.numTasks );
			assertEquals( 0, _compositeTask.numInternalOperationsPending, _compositeTask.numPendingTasks );
		}
		
		[Test]
		public function testNumInternalOperationsNested():void {
			_compositeTask.addMultiple(
				new StubTask( true ),
				function():void {},
				new CompositeTask( [ new StubTask( true ), new StubTask( true ) ] ) );
			
			assertEquals( 4, _compositeTask.numInternalOperations, _compositeTask.numInternalOperationsPending );
			assertEquals( 0, _compositeTask.numInternalOperationsCompleted );
			assertEquals( 3, _compositeTask.numTasks, _compositeTask.numPendingTasks );
			
			_compositeTask.run();
			
			assertEquals( 4, _compositeTask.numInternalOperations, _compositeTask.numInternalOperationsCompleted );
			assertEquals( 0, _compositeTask.numInternalOperationsPending, _compositeTask.numPendingTasks );
			assertEquals( 3, _compositeTask.numTasks );
		}
		
		[Test]
		public function testProgressEventsReflectTheCorrectNumberOfInternalOperations():void {
			_compositeTask.addMultiple(
				new StubTask( true ),
				function():void {},
				new CompositeTask( [ new StubTask( true ), new StubTask( true ) ] ) );
			
			var numProgressEvents:int = 0;
			var allAssertionsPassed:Boolean = true;
			
			_compositeTask.addEventListener(
				ProgressEvent.PROGRESS,
				function( event:ProgressEvent ):void {
					numProgressEvents++;
					
					if ( event.bytesLoaded != numProgressEvents && event.bytesTotal != 4 ) {
						allAssertionsPassed = false;
					}
				} );
			
			_compositeTask.run();
			
			assertEquals( 4, numProgressEvents );
			assertTrue( allAssertionsPassed );
		}
		
		// Tests pertaining to flush-queue methods
		
		[Test]
		public function testFlushQueue_forcefullyPreventTaskFromCompleting_true():void {
			for each ( var executeTaskInParallel:Boolean in [ true, false ] ) {
				var compositeTask:CompositeTaskSubClassThatFlushesQueue = new CompositeTaskSubClassThatFlushesQueue( executeTaskInParallel );
				compositeTask.setupQueuePhaseOne();
				compositeTask.run();
				
				assertTrue( compositeTask.running );
				assertEquals( compositeTask.phaseOne_numTasks, compositeTask.numTasks );
				
				compositeTask.doFlushTaskQueue( true );
				
				assertTrue( compositeTask.running );
				assertEquals( 0, compositeTask.numTasks );
			}
		}
		
		[Test]
		public function testFlushQueue_forcefullyPreventTaskFromCompleting_false():void {
			for each ( var executeTaskInParallel:Boolean in [ true, false ] ) {
				var compositeTask:CompositeTaskSubClassThatFlushesQueue = new CompositeTaskSubClassThatFlushesQueue( executeTaskInParallel );
				compositeTask.setupQueuePhaseOne();
				compositeTask.run();
				
				assertTrue( compositeTask.running );
				assertEquals( compositeTask.phaseOne_numTasks, compositeTask.numTasks );
				
				compositeTask.doFlushTaskQueue( false );
				
				assertTrue( compositeTask.isComplete );
				assertEquals( 0, compositeTask.numTasks );
			}
		}
		
		[Test]
		public function testFlushQueue_whenQueueEmpty():void {
			for each ( var executeTaskInParallel:Boolean in [ true, false ] ) {
				var compositeTask:CompositeTaskSubClassThatFlushesQueue = new CompositeTaskSubClassThatFlushesQueue( executeTaskInParallel );
				
				// Flush queue when empty and not running - should do nothing (should not break)
				compositeTask.doFlushTaskQueue( false );
			}
		}
		
		[Test]
		public function testFlushQueue_whenCompositeNotRunning_shouldNotDispatchCompleteEvent():void {
			for each ( var executeTaskInParallel:Boolean in [ true, false ] ) {
				var compositeTask:CompositeTaskSubClassThatFlushesQueue = new CompositeTaskSubClassThatFlushesQueue( executeTaskInParallel );
				compositeTask.setupQueuePhaseOne();
				
				assertFalse( compositeTask.running, compositeTask.isComplete );
				
				compositeTask.doFlushTaskQueue( false );
				
				// Should not have completed because composite wasn't running
				assertFalse( compositeTask.running, compositeTask.isComplete );
				
				// Should not have interrupted any of our child tasks because they weren't running either
				assertEquals( 0,
				              compositeTask.phaseOne_stubTask_1.numTimesInterrupted,
				              compositeTask.phaseOne_stubTask_2.numTimesInterrupted,
				              compositeTask.phaseOne_stubTask_3.numTimesInterrupted );
				
				compositeTask.run();
				
				// Should have auto-completed because queue was empty
				assertTrue( compositeTask.isComplete );
			}
		}
		
		[Test]
		public function testFlushQueue_andAddNewSetOfTasks():void {
			var compositeTask:CompositeTaskSubClassThatFlushesQueue = new CompositeTaskSubClassThatFlushesQueue( false );
			compositeTask.setupQueuePhaseOne();
			compositeTask.run();
			
			assertTrue( compositeTask.running, compositeTask.phaseOne_stubTask_1.running );
			assertEquals( compositeTask.phaseOne_numTasks, compositeTask.numTasks );
			
			compositeTask.doFlushTaskQueue( true );
			
			assertTrue( compositeTask.running );
			assertEquals( 0, compositeTask.numTasks );
			assertEquals( 1, compositeTask.phaseOne_stubTask_1.numTimesStarted, compositeTask.phaseOne_stubTask_1.numTimesInterrupted );
			assertEquals( 0, compositeTask.phaseOne_stubTask_2.numTimesStarted, compositeTask.phaseOne_stubTask_2.numTimesInterrupted );
			
			compositeTask.setupQueuePhaseTwo();
			
			assertTrue( compositeTask.running, compositeTask.phaseTwo_stubTask_1.running );
			assertEquals( compositeTask.phaseTwo_numTasks, compositeTask.numTasks );
			
			compositeTask.phaseTwo_stubTask_1.complete();
			
			assertTrue( compositeTask.running, compositeTask.phaseTwo_stubTask_2.running );
			
			compositeTask.phaseTwo_stubTask_2.complete();
			
			assertEquals( 1, compositeTask.phaseTwo_stubTask_1.numTimesStarted, compositeTask.phaseTwo_stubTask_2.numTimesStarted );
			
			assertTrue( compositeTask.isComplete );
		}
		
		[Test]
		public function testFlushQueue_tasksThatHavePreviouslyCompletedDoNotHaveCompleteHandlersInvokedTwice():void {
			for each ( var executeTaskInParallel:Boolean in [ true, false ] ) {
				var compositeTask:CompositeTaskSubClassThatFlushesQueue = new CompositeTaskSubClassThatFlushesQueue( executeTaskInParallel );
				compositeTask.setupQueuePhaseOne();
				compositeTask.run();
				
				var numCompleteEvents:int = 0;
				var numCompleteHandlerInvocations:int = 0;
				
				compositeTask.phaseOne_stubTask_1.addEventListener(
					TaskEvent.COMPLETE,
					function( event:TaskEvent ):void {
						numCompleteEvents++;
					} );
				compositeTask.phaseOne_stubTask_1.withCompleteHandler(
					function():void {
						numCompleteHandlerInvocations++;
					} );
				
				compositeTask.phaseOne_stubTask_1.complete();
				
				assertEquals( 1, numCompleteEvents, numCompleteHandlerInvocations );
				
				compositeTask.doFlushTaskQueue( false );
				
				assertEquals( 1, numCompleteEvents, numCompleteHandlerInvocations );
			}
		}
		
		// Individual Task started/completed hook methods
		
		[Test]
		public function test_individualTaskStartedAndCompletedHookMethods():void {
			var stubTask1:StubTask = new StubTask();
			var stubTask2:StubTask = new StubTask();
			
			var compositeTask:StubCompositeTaskThatTracksHookMethodInvocations = new StubCompositeTaskThatTracksHookMethodInvocations();
			compositeTask.addMultiple( stubTask1, stubTask2 );
			
			assertEquals( 0, compositeTask.individualTasksCompleted.length, compositeTask.individualTasksStarted.length );
			
			compositeTask.run();
			
			assertEquals( 1, compositeTask.individualTasksStarted.length );
			assertTrue( compositeTask.individualTasksStarted.indexOf( stubTask1 ) >= 0 );
			assertEquals( 0, compositeTask.individualTasksCompleted.length );
			
			stubTask1.complete();
			
			assertEquals( 2, compositeTask.individualTasksStarted.length );
			assertTrue( compositeTask.individualTasksStarted.indexOf( stubTask1 ) >= 0 );
			assertTrue( compositeTask.individualTasksStarted.indexOf( stubTask2 ) >= 0 );
			assertEquals( 1, compositeTask.individualTasksCompleted.length );
			assertTrue( compositeTask.individualTasksCompleted.indexOf( stubTask1 ) >= 0 );
			
			stubTask2.complete();
			
			assertEquals( 2, compositeTask.individualTasksStarted.length );
			assertTrue( compositeTask.individualTasksStarted.indexOf( stubTask1 ) >= 0 );
			assertTrue( compositeTask.individualTasksStarted.indexOf( stubTask2 ) >= 0 );
			assertEquals( 2, compositeTask.individualTasksCompleted.length );
			assertTrue( compositeTask.individualTasksCompleted.indexOf( stubTask1 ) >= 0 );
			assertTrue( compositeTask.individualTasksCompleted.indexOf( stubTask2 ) >= 0 );
		}
		
		// Resume after error behavior
		
		[Test]
		public function test_resumeAfterError_singleTaskErrors_serialComposite():void {
			var innerTaskOne:StubTask = new StubTask();
			var innerTaskTwo:StubTask = new StubTask();
			var innerTaskThree:StubTask = new StubTask();
			
			_compositeTask = new CompositeTask( [ innerTaskOne, innerTaskTwo, innerTaskThree ], false );
			
			assertEquals( 0, innerTaskOne.numTimesStarted, innerTaskTwo.numTimesStarted, innerTaskThree.numTimesStarted );
			
			_compositeTask.run();
			
			assertEquals( 1, innerTaskOne.numTimesStarted );
			assertEquals( 0, innerTaskTwo.numTimesStarted, innerTaskThree.numTimesStarted );
			
			innerTaskOne.complete();
			
			assertEquals( 1, innerTaskOne.numTimesStarted, innerTaskTwo.numTimesStarted );
			assertEquals( 0, innerTaskThree.numTimesStarted );
			
			innerTaskTwo.error();
			
			assertEquals( 1, innerTaskOne.numTimesCompleted );
			assertEquals( 1, innerTaskTwo.numTimesErrored );
			assertEquals( 0, innerTaskThree.numTimesStarted );
			
			_compositeTask.run();
			
			assertEquals( 1, innerTaskOne.numTimesStarted, innerTaskOne.numTimesCompleted );
			assertEquals( 2, innerTaskTwo.numTimesStarted );
			assertEquals( 1, innerTaskTwo.numTimesErrored );
			assertEquals( 0, innerTaskThree.numTimesStarted );
			
			innerTaskTwo.complete();
			innerTaskThree.complete();
			
			assertEquals( 1, innerTaskOne.numTimesStarted, innerTaskOne.numTimesCompleted );
			assertEquals( 2, innerTaskTwo.numTimesStarted );
			assertEquals( 1, innerTaskTwo.numTimesErrored, innerTaskTwo.numTimesCompleted );
			assertEquals( 1, innerTaskThree.numTimesStarted, innerTaskThree.numTimesCompleted );
		}
		
		[Test]
		public function test_resumeAfterError_singleTaskErrors_parallelComposite():void {
			var innerTaskOne:StubTask = new StubTask();
			var innerTaskTwo:StubTask = new StubTask();
			var innerTaskThree:StubTask = new StubTask();
			
			_compositeTask = new CompositeTask( [ innerTaskOne, innerTaskTwo, innerTaskThree ], true );
			
			assertEquals( 0, innerTaskOne.numTimesStarted, innerTaskTwo.numTimesStarted, innerTaskThree.numTimesStarted );
			
			_compositeTask.run();
			
			assertEquals( 1, innerTaskOne.numTimesStarted, innerTaskTwo.numTimesStarted, innerTaskThree.numTimesStarted );
			
			innerTaskTwo.error();
			
			assertTrue( _compositeTask.running );	// Does not error until all inner-Tasks have errored.
			assertEquals( 0, _compositeTask.numTimesErrored );
			assertEquals( 1, innerTaskTwo.numTimesErrored );
			
			innerTaskOne.complete();
			innerTaskThree.complete();
			
			assertFalse( _compositeTask.running );
			assertEquals( 1, innerTaskTwo.numTimesErrored, _compositeTask.numTimesErrored );
			assertEquals( 1, innerTaskOne.numTimesCompleted, innerTaskThree.numTimesCompleted );
			
			_compositeTask.run();
			
			assertTrue( _compositeTask.running );
			assertEquals( 1, innerTaskOne.numTimesStarted, innerTaskThree.numTimesStarted );	// Should not be restarted since they were previously completed.
			assertEquals( 2, innerTaskTwo.numTimesStarted, _compositeTask.numTimesStarted );
			
			innerTaskTwo.complete();
			
			assertFalse( _compositeTask.running );
			assertEquals( 1, innerTaskTwo.numTimesErrored, _compositeTask.numTimesErrored );
			assertEquals( 1, innerTaskOne.numTimesCompleted, innerTaskTwo.numTimesCompleted, innerTaskThree.numTimesCompleted, _compositeTask.numTimesCompleted );
		}
		
		[Test]
		public function test_resumeAfterError_multipleTasksError_parallelComposite():void {
			var innerTaskOne:StubTask = new StubTask();
			var innerTaskTwo:StubTask = new StubTask();
			var innerTaskThree:StubTask = new StubTask();
			
			_compositeTask = new CompositeTask( [ innerTaskOne, innerTaskTwo, innerTaskThree ], true );
			_compositeTask.run();
			
			assertEquals( 1, innerTaskOne.numTimesStarted, innerTaskTwo.numTimesStarted, innerTaskThree.numTimesStarted );
			
			innerTaskOne.error();
			innerTaskTwo.complete();
			innerTaskThree.error();
			
			assertFalse( _compositeTask.running );
			assertEquals( 1, innerTaskOne.numTimesErrored, innerTaskTwo.numTimesCompleted, innerTaskThree.numTimesErrored, _compositeTask.numTimesErrored );
			
			_compositeTask.run();
			
			assertTrue( _compositeTask.running );
			assertEquals( 2, _compositeTask.numPendingTasks );
			assertEquals( 1, innerTaskTwo.numTimesStarted );
			assertEquals( 2, innerTaskOne.numTimesStarted, innerTaskThree.numTimesStarted );
			
			innerTaskOne.complete();
			innerTaskThree.error();
			
			assertFalse( _compositeTask.running );
			assertEquals( 1, innerTaskOne.numTimesCompleted, innerTaskTwo.numTimesCompleted );
			assertEquals( 2, innerTaskThree.numTimesErrored, _compositeTask.numTimesErrored );
			
			_compositeTask.run();
			
			assertTrue( _compositeTask.running );
			assertEquals( 1, _compositeTask.numPendingTasks );
			assertEquals( 2, innerTaskOne.numTimesStarted );
			assertEquals( 1, innerTaskTwo.numTimesStarted );
			assertEquals( 3, innerTaskThree.numTimesStarted );
			
			innerTaskThree.complete();
			
			assertTrue( _compositeTask.isComplete );
			assertEquals( 1, innerTaskOne.numTimesCompleted, innerTaskTwo.numTimesCompleted, innerTaskThree.numTimesCompleted, _compositeTask.numTimesCompleted );
		}
	}
}

import com.rosettastone.library.taskmanager.CompositeTask;
import com.rosettastone.library.taskmanager.ITask;
import com.rosettastone.library.taskmanager.StubTask;
import com.rosettastone.library.taskmanager.Task;

import org.flexunit.assertThat;
import org.flexunit.asserts.assertFalse;

class StubCompositeTaskThatAddsStubTasksBeforeRun extends CompositeTask {
	
	private var _stubTask:StubTask;
	
	public function StubCompositeTaskThatAddsStubTasksBeforeRun() {
		super( null, true, "Private class used by TestCompositeTask unit test" );
	}
	
	override protected function addTasksBeforeRun():void {
		_stubTask = new StubTask();
		
		addTask( _stubTask );
		
		assertFalse( _stubTask.running );
	}
	
	override protected function customRun():void {
		super.customRun();
		
		assertThat( _stubTask.running );
	}
}

class StubCompositeTaskThatTracksHookMethodInvocations extends CompositeTask {
	
	public var individualTasksCompleted:Array;
	public var individualTasksStarted:Array;
	
	public function StubCompositeTaskThatTracksHookMethodInvocations() {
		super( null, false, "Private class used by TestCompositeTask unit test" );
		
		individualTasksCompleted = new Array();
		individualTasksStarted = new Array();
	}
	
	override protected function individualTaskComplete( task:ITask ):void {
		individualTasksCompleted.push( task );
	}
	
	override protected function individualTaskStarted( task:ITask ):void {
		individualTasksStarted.push( task );
	}
}