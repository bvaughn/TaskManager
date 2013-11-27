package com.rosettastone.library.taskmanager {
	use namespace TaskPrivateNamespace;
	
	/**
	 * Although this test tests Task functionality it instantiates a StubTask.
	 * This is because Task by itself has no customRun() function and throws an error when run.
	 */
	public class TestTask extends AbstractTaskTestCase {
		
		private var _task:Task;
		
		[Before]
		override public function setUp():void {
			super.setUp();
			
			_task = new StubTask();
		}
		
		[Test]
		public function testTaskIdentifier():void {
			var task:ITask = new Task( "foo" );
			
			assertEquals( "foo", task.taskIdentifier );
			
			task.taskIdentifier = "bar";
			
			assertEquals( "bar", task.taskIdentifier );
		}
		
		[Test]
		public function taskTaskIdAndUniqueId():void {
			var task:ITask = new Task();
			
			assertEquals( task.id, task.uniqueID );
		}
		
		[Test]
		public function testTaskWithNoOperationsThrowsError():void {
			var errorThrown:Boolean = false;
			
			try {
				_task = new Task();
				_task.run();
			} catch ( error:Error ) {
				errorThrown = true;
			}
			
			assertTrue( errorThrown );
		}
		
		[Test]
		public function testNonRunningTaskDoesNotDispatchEvents():void {
			addTaskEventListeners( _task );
			
			_task.doTaskComplete();
			_task.doTaskError( "Error" );
			_task.doTaskInterrupted();
			
			assertNumEvents( 0, 0, 0 );
		}
		
		[Test]
		public function testMultipleCompletesOnlyDispatchOneEvent():void {
			addTaskEventListeners( _task );
			
			_task.run();
			_task.doTaskComplete();
			
			assertNumEvents( 1, 0, 0 );
			
			_task.doTaskComplete();
			
			assertNumEvents( 1, 0, 0 );
		}
		
		[Test]
		public function testMultipleErrorsOnlyDispatchOneEvent():void {
			addTaskEventListeners( _task );
			
			_task.run();
			_task.doTaskError( "Error" );
			
			assertNumEvents( 0, 1, 0 );
			
			_task.doTaskError( "Error" );
			
			assertNumEvents( 0, 1, 0 );
		}
		
		[Test]
		public function testMultipleInterruptionsOnlyDispatchOneEvent():void {
			addTaskEventListeners( _task );
			
			_task.run();
			_task.doTaskInterrupted();
			
			assertNumEvents( 0, 0, 1 );
			
			_task.doTaskInterrupted();
			
			assertNumEvents( 0, 0, 1 );
		}
		
		[Test]
		public function testWithCompleteHandler():void {
			_task = new StubTask();
			_task.withCompleteHandler( completeHandler );
			_task.withErrorHandler( errorHandler );
			_task.withInterruptionHandler( interruptionHandler );
			_task.run();
			
			assertNumEvents( 0, 0, 0 );
			
			var data:* = { "foo" : "bar" };
			
			_task.doTaskComplete( "Test", data );
			
			assertNumEvents( 1, 0, 0 );
			assertEquals( "Test", _message, _task.message );
			assertEquals( data, _data, _task.data );
		}
		
		[Test]
		public function testWithCompleteHandlerAddingSameHandlerTwiceOnlyInvokesOnce():void {
			_task = new StubTask();
			_task.withCompleteHandler( completeHandler );
			_task.withErrorHandler( errorHandler );
			_task.withInterruptionHandler( interruptionHandler );
			_task.run();
			
			_task.doTaskComplete();
			
			assertNumEvents( 1, 0, 0 );
		}
		
		[Test]
		public function testWithCompleteHandlerUsingMultipleHandlers():void {
			var completeHandler1Invoked:Boolean;
			var completeHandler1:Function =
				function():void {
					completeHandler1Invoked = true;
				};
			
			var completeHandler2Invoked:Boolean;
			var completeHandler2:Function =
				function():void {
					completeHandler2Invoked = true;
				};
			
			_task = new StubTask();
			_task.withCompleteHandler( completeHandler1 );
			_task.withCompleteHandler( completeHandler2 );
			_task.run();
			
			_task.doTaskComplete();
			
			assertTrue( completeHandler1Invoked, completeHandler2Invoked );
		}
		
		[Test]
		public function testWithCompleteHandlerNoParametersAccepted():void {
			var completeHandlerWithoutParameters:Function =
				function():void {
					_numCompleteEvents++;
				};
			
			_task = new StubTask();
			_task.withCompleteHandler( completeHandlerWithoutParameters );
			_task.withErrorHandler( errorHandler );
			_task.withInterruptionHandler( interruptionHandler );
			_task.run();
			
			assertNumEvents( 0, 0, 0 );
			
			_task.doTaskComplete( "Test", { "foo" : "bar" } );
			
			assertNumEvents( 1, 0, 0 );
		}
		
		[Test]
		public function testWithErrorHandler():void {
			_task = new StubTask();
			_task.withCompleteHandler( completeHandler );
			_task.withErrorHandler( errorHandler );
			_task.withInterruptionHandler( interruptionHandler );
			_task.run();
			
			assertNumEvents( 0, 0, 0 );
			
			var data:* = { "foo" : "bar" };
			
			_task.doTaskError( "Error", data );
			
			assertNumEvents( 0, 1, 0 );
			assertEquals( "Error", _message, _task.message );
			assertEquals( data, _data, _task.data );
		}
		
		[Test]
		public function testWithErrorHandlerAddingSameHandlerTwiceOnlyInvokesOnce():void {
			_task = new StubTask();
			_task.withErrorHandler( errorHandler );
			_task.withErrorHandler( errorHandler );
			_task.run();
			
			_task.doTaskError();
			
			assertNumEvents( 0, 1, 0 );
		}
		
		[Test]
		public function testWithErrorHandlerUsingMultipleHandlers():void {
			var errorHandler1Invoked:Boolean;
			var errorHandler1:Function =
				function():void {
					errorHandler1Invoked = true;
				};
			
			var errorHandler2Invoked:Boolean;
			var errorHandler2:Function =
				function():void {
					errorHandler2Invoked = true;
				};
			
			_task = new StubTask();
			_task.withErrorHandler( errorHandler1 );
			_task.withErrorHandler( errorHandler2 );
			_task.run();
			
			_task.doTaskError();
			
			assertTrue( errorHandler1Invoked, errorHandler2Invoked );
		}
		
		[Test]
		public function testWithErrorHandlerNoParametersAccepted():void {
			var errorHandlerWithoutParameters:Function =
				function():void {
					_numErrorEvents++;
				};
			
			_task = new StubTask();
			_task.withCompleteHandler( completeHandler );
			_task.withErrorHandler( errorHandlerWithoutParameters );
			_task.withInterruptionHandler( interruptionHandler );
			_task.run() as Task;
			
			assertNumEvents( 0, 0, 0 );
			
			var data:* = { "foo" : "bar" };
			
			_task.doTaskError( "Error", { "foo" : "bar" } );
			
			assertNumEvents( 0, 1, 0 );
		}
		
		[Test]
		public function testWithFinalHandler_failedTask():void {
			_task = new StubTask();
			_task.withErrorHandler( errorHandler );
			_task.withFinalHandler( finalHandler );
			_task.run();
			
			assertNumEvents( 0, 0, 0 );
			
			_task.doTaskError();
			
			assertNumEvents( 0, 1, 0 );
			assertEquals( 1, _numFinalEvents );
		}
		
		[Test]
		public function testWithFinalHandler_interruptedTask():void {
			_task = new InterruptibleStubTask();
			_task.withInterruptionHandler( interruptionHandler );
			_task.withFinalHandler( finalHandler );
			_task.run();
			
			assertNumEvents( 0, 0, 0 );
			
			_task.interrupt();
			
			assertNumEvents( 0, 0, 1 );
			assertEquals( 0, _numFinalEvents );
		}
		
		[Test]
		public function testWithFinalHandler_successfulTask():void {
			_task = new StubTask();
			_task.withCompleteHandler( completeHandler );
			_task.withFinalHandler( finalHandler );
			_task.run();
			
			assertNumEvents( 0, 0, 0 );
			
			_task.doTaskComplete();
			
			assertNumEvents( 1, 0, 0 );
			assertEquals( 1, _numFinalEvents );
		}
		
		[Test]
		public function testWithInterruptionHandler():void {
			_task = new StubTask();
			_task.withCompleteHandler( completeHandler );
			_task.withErrorHandler( errorHandler );
			_task.withInterruptionHandler( interruptionHandler );
			_task.run() as Task;
			
			assertNumEvents( 0, 0, 0 );
			
			var data:* = { "foo" : "bar" };
			
			_task.doTaskInterrupted( "Interrupted", data );
			
			assertNumEvents( 0, 0, 1 );
			assertEquals( "Interrupted", _message, _task.message );
			assertEquals( data, _data, _task.data );
		}
		
		[Test]
		public function testWithInterruptionHandlerAddingSameHandlerTwiceOnlyInvokesOnce():void {
			_task = new InterruptibleStubTask();
			_task.withInterruptionHandler( interruptionHandler );
			_task.withInterruptionHandler( interruptionHandler );
			_task.run();
			
			_task.interrupt();
			
			assertNumEvents( 0, 0, 1 );
		}
		
		[Test]
		public function testWithInterruptionHandlerUsingMultipleHandlers():void {
			var interruptionHandler1Invoked:Boolean;
			var interruptionHandler1:Function =
				function():void {
					interruptionHandler1Invoked = true;
				};
			
			var interruptionHandler2Invoked:Boolean;
			var interruptionHandler2:Function =
				function():void {
					interruptionHandler2Invoked = true;
				};
			
			_task = new InterruptibleStubTask();
			_task.withInterruptionHandler( interruptionHandler1 );
			_task.withInterruptionHandler( interruptionHandler2 );
			_task.run();
			
			_task.interrupt();
			
			assertTrue( interruptionHandler1Invoked, interruptionHandler2Invoked );
		}
		
		[Test]
		public function testWithInterruptionHandlerNoParametersAccepted():void {
			var interruptionHandlerWithoutParameters:Function =
				function():void {
					_numInterruptedEvents++;
				};
			
			_task = new StubTask();
			_task.withCompleteHandler( completeHandler );
			_task.withErrorHandler( errorHandler );
			_task.withInterruptionHandler( interruptionHandlerWithoutParameters );
			_task.run();
			
			assertNumEvents( 0, 0, 0 );
			
			_task.doTaskInterrupted( "Interrupted" );
			
			assertNumEvents( 0, 0, 1 );
		}
		
		[Test]
		public function testWithStartedHandler():void {
			var numStartedInvocations:int = 0;
			
			_task = new InterruptibleStubTask();
			_task.withStartedHandler(
					function():void {
						numStartedInvocations++;
					} );
			
			assertEquals( 0, numStartedInvocations );
			
			_task.run();
			
			assertEquals( 1, numStartedInvocations );
			
			_task.interrupt();
			
			assertEquals( 1, numStartedInvocations );
			
			_task.run();
			
			assertEquals( 2, numStartedInvocations );
		}
		
		[Test]
		public function testWithStartedHandlerAddingSameHandlerTwiceOnlyInvokesOnce():void {
			_task = new StubTask();
			_task.withStartedHandler( startedHandler );
			_task.withStartedHandler( startedHandler );
			_task.run();
			
			assertEquals( 1, _numStartedEvents );
		}
		
		[Test]
		public function testWithStartedHandlerUsingMultipleHandlers():void {
			var startedHandler1Invoked:Boolean;
			var startedHandler1:Function =
				function():void {
					startedHandler1Invoked = true;
				};
			
			var startedHandler2Invoked:Boolean;
			var startedHandler2:Function =
				function():void {
					startedHandler2Invoked = true;
				};
			
			_task = new StubTask();
			_task.withStartedHandler( startedHandler1 );
			_task.withStartedHandler( startedHandler2 );
			_task.run();
			
			assertTrue( startedHandler1Invoked, startedHandler2Invoked );
		}
		
		/*
		 * Chaining methods
		 */
		
		[Test]
		public function testChainingThenExecutesChainedTaskIfCurrentTaskCompletes():void {
			var task:StubTask = new StubTask();
			var chainedTask1:StubTask = new StubTask();
			var chainedTask2:StubTask = new StubTask();
			
			task.then( chainedTask1, chainedTask2 ).run();
			
			assertTrue( task.running );
			assertFalse( chainedTask1.running );
			assertFalse( chainedTask2.running );
			
			task.complete();
			
			assertFalse( task.running );
			assertTrue( chainedTask1.running );
			assertTrue( chainedTask2.running );
		}
		
		[Test]
		public function testChainingThenDoesNotExecuteChainedTaskIfCurrentTaskFails():void {
			var task:StubTask = new StubTask();
			var chainedTask1:StubTask = new StubTask();
			var chainedTask2:StubTask = new StubTask();
			
			task.then( chainedTask1, chainedTask2 ).run();
			
			assertTrue( task.running );
			assertFalse( chainedTask1.running );
			assertFalse( chainedTask2.running );
			
			task.error();
			
			assertFalse( task.running );
			assertFalse( chainedTask1.running );
			assertFalse( chainedTask2.running );
		}
		
		[Test]
		public function testChainingOrExecutesChainedTaskIfCurrentTaskFails():void {
			var task:StubTask = new StubTask();
			var chainedTask1:StubTask = new StubTask();
			var chainedTask2:StubTask = new StubTask();
			
			task.or( chainedTask1, chainedTask2 ).run();
			
			assertTrue( task.running );
			assertFalse( chainedTask1.running );
			assertFalse( chainedTask2.running );
			
			task.error();
			
			assertFalse( task.running );
			assertTrue( chainedTask1.running );
			assertTrue( chainedTask2.running );
		}
		
		[Test]
		public function testChainingOrDoesNotExecuteChainedTaskIfCurrentTaskSucceeds():void {
			var task:StubTask = new StubTask();
			var chainedTask1:StubTask = new StubTask();
			var chainedTask2:StubTask = new StubTask();
			
			task.or( chainedTask1, chainedTask2 ).run();
			
			assertTrue( task.running );
			assertFalse( chainedTask1.running );
			assertFalse( chainedTask2.running );
			
			task.complete();
			
			assertFalse( task.running );
			assertFalse( chainedTask1.running );
			assertFalse( chainedTask2.running );
		}
		
		[Test]
		public function testChainingAndExecutesChainedTaskOnceCurrentTaskStarts():void {
			var task:StubTask = new StubTask();
			var chainedTask1:StubTask = new StubTask();
			var chainedTask2:StubTask = new StubTask();
			
			task.and( chainedTask1, chainedTask2 );
			
			assertFalse( task.running );
			assertFalse( chainedTask1.running );
			assertFalse( chainedTask2.running );
			
			task.run();
			
			assertTrue( task.running );
			assertTrue( chainedTask1.running );
			assertTrue( chainedTask2.running );
		}
		
		[Test]
		public function testChainingAndExecutesChainedTaskIfCurrentTaskHasAlreadyStarted():void {
			var task:StubTask = new StubTask();
			var chainedTask1:StubTask = new StubTask();
			var chainedTask2:StubTask = new StubTask();
			
			task.run().and( chainedTask1, chainedTask2 );
			
			assertTrue( task.running );
			assertTrue( chainedTask1.running );
			assertTrue( chainedTask2.running );
		}
		
		[Test]
		public function testComplexChaining():void {
			var firstTask:StubTask = new StubTask();
			var secondTask:StubTask = new StubTask();
			var fallBackTask:StubTask = new StubTask();
			var parallelTask:StubTask = new StubTask();
			
			firstTask.then( secondTask.or( fallBackTask.and( parallelTask ) ) ).run();
			
			assertTrue( firstTask.running );
			assertFalse( secondTask.running, fallBackTask.running, parallelTask.running );
			
			firstTask.complete();
			
			assertTrue( secondTask.running );
			assertFalse( firstTask.running, fallBackTask.running, parallelTask.running );
			
			secondTask.error();
			
			assertTrue( fallBackTask.running, parallelTask.running );
			assertFalse( firstTask.running, secondTask.running );
		}
		
		[Test]
		public function testAndOrAndThenThrowsErrorsIfNonTaskParameterSpecified():void {
			for ( var index:int = 0; index < 3; index++ ) {
				var errorThrown:Boolean = false;
				var task:ITask = new Task();
				
				try {
					switch ( index ) {
						case 0:
							task.and( new Object() );
							break;
						case 1:
							task.or( new Object() );
							break;
						case 2:
							task.then( new Object() );
							break;
					}
				} catch ( error:Error ) {
					errorThrown = true;
				}
				
				assertTrue( errorThrown );
			}
		}
		
		[Test]
		public function testNumInternalOperations():void {
			assertEquals( 1, _task.numInternalOperations, _task.numInternalOperationsPending );
			assertEquals( 0, _task.numInternalOperationsCompleted );
			
			_task.run();
			
			assertEquals( 1, _task.numInternalOperations, _task.numInternalOperationsPending );
			assertEquals( 0, _task.numInternalOperationsCompleted );
			
			_task.doTaskComplete();
			
			assertEquals( 1, _task.numInternalOperations, _task.numInternalOperationsCompleted );
			assertEquals( 0, _task.numInternalOperationsPending );
		}
		
		[Test]
		public function testTaskOnlyRunsOnceIfRunIsCalledMultipleTimesInARow():void {
			var stubTask:StubTask = new StubTask();
			
			assertEquals( 0, stubTask.numTimesStarted );
			
			stubTask.run();
			
			assertEquals( 1, stubTask.numTimesStarted );
			
			stubTask.run();
			
			assertEquals( 1, stubTask.numTimesStarted );
		}
		
		// Reset tests
		
		[Test]
		public function testResetTaskResetsCompleteState():void {
			var stubTask:StubTask = new StubTask( true );
			stubTask.run();
			
			assertTrue( stubTask.isComplete );
			
			stubTask.reset();
			
			assertFalse( stubTask.isComplete );
		}
		
		[Test]
		public function testResetTaskResetsInterruptedState():void {
			var stubTask:InterruptibleStubTask = new InterruptibleStubTask();
			stubTask.run();
			stubTask.interrupt();
			
			assertTrue( stubTask.isInterrupted );
			
			stubTask.reset();
			
			assertFalse( stubTask.isInterrupted );
		}
		
		[Test]
		public function testResetTaskResetsErroredState():void {
			var stubTask:StubTask = new StubTask();
			stubTask.run();
			stubTask.error();
			
			assertTrue( stubTask.isErrored );
			
			stubTask.reset();
			
			assertFalse( stubTask.isErrored );
		}
		
		[Test]
		public function testCannotResetTaskThatIsRunning():void {
			var stubTask:StubTask = new StubTask();
			stubTask.run();
			
			assertTrue( stubTask.running );
			
			stubTask.reset();
			
			assertTrue( stubTask.running );
		}
		
		[Test]
		public function testReset_doesNotResetIfNotRunBefore():void {
			var stubTask:StubTask = new StubTask();
			stubTask.reset();
			
			assertEquals( 0, stubTask.numTimesReset );
		}
		
		[Test]
		public function testResetResetsAllEventCounters():void {
			var stubTask:StubTask = new StubTask( true );
			stubTask.run();
			
			assertEquals( 1, stubTask.numTimesStarted, stubTask.numTimesCompleted );
			
			stubTask.reset();
			
			
			assertEquals( 0, stubTask.numTimesStarted, stubTask.numTimesCompleted );
		}
		
		// Below this line are tests related to interruptForTask()
		
		[Test]
		public function testInterruptForTaskIfTaskIsNotInterruptible():void {
			addTaskEventListeners( _task );
			
			var stubTask:StubTask = new StubTask();
			
			_task.run();
			_task.interruptForTask( stubTask );
			
			assertTrue( _task.running );
			assertFalse( stubTask.running );
			assertNumEvents( 0, 0, 0 );
		}
		
		[Test]
		public function testInterruptForTaskIfTaskIsNotRunning():void {
			_task = new InterruptibleStubTask();
			
			addTaskEventListeners( _task );
			
			var stubTask:StubTask = new StubTask();
			
			_task.interruptForTask( stubTask );
			
			assertFalse( _task.running );
			assertNumEvents( 0, 0, 0 );
			
			stubTask.run();
			stubTask.complete();
			
			assertFalse( _task.running );
			assertNumEvents( 0, 0, 0 );
		}
		
		[Test]
		public function testInterruptForTaskWithInterruptingTaskThatCompletes():void {
			_task = new InterruptibleStubTask();
			_task.run();
			
			addTaskEventListeners( _task );
			
			var stubTask:StubTask = new StubTask();
			
			_task.interruptForTask( stubTask );
			
			assertFalse( _task.running );
			assertNumEvents( 0, 0, 1 );
			
			stubTask.run();
			stubTask.complete();
			
			assertTrue( _task.running );
			assertNumEvents( 0, 0, 1 );
		}
		
		[Test]
		public function testInterruptForTaskWithInterruptingTaskThatErrors():void {
			_task = new InterruptibleStubTask();
			_task.run();
			
			addTaskEventListeners( _task );
			
			var stubTask:StubTask = new StubTask();
			
			_task.interruptForTask( stubTask );
			
			assertFalse( _task.running );
			assertNumEvents( 0, 0, 1 );
			
			stubTask.run();
			stubTask.error();
			
			assertFalse( _task.running );
			assertNumEvents( 0, 1, 1 );
		}
		
		[Test]
		public function testInterruptionForTaskDoesNotStartNonRunningInterruptingTask():void {
			_task = new InterruptibleStubTask();
			_task.run();
			
			assertTrue( _task.running );
			
			var stubTask:StubTask = new StubTask();
			
			_task.interruptForTask( stubTask );
			
			assertFalse( stubTask.running );
			assertFalse( _task.running );
			
			stubTask.run();
			
			assertTrue( stubTask.running );
			assertFalse( _task.running );
		}
		
		[Test]
		public function testInterruptionForTaskThenManualResumeDoesNotResultInMultipleCallsToRun():void {
			_task = new InterruptibleStubTask();
			
			addTaskEventListeners( _task );
			
			_task.run();
			
			assertEquals( 1, _numStartedEvents );
			
			var stubTask:StubTask = new StubTask();
			stubTask.run();
			
			_task.interruptForTask( stubTask );
			
			assertFalse( _task.running );
			assertEquals( 1, _numStartedEvents );
			assertNumEvents( 0, 0, 1 );
			
			_task.run();
			
			assertTrue( _task.running );
			assertEquals( 2, _numStartedEvents );
			assertNumEvents( 0, 0, 1 );
			
			stubTask.complete();
			
			assertTrue( _task.running );
			assertEquals( 2, _numStartedEvents );
			assertNumEvents( 0, 0, 1 );
		}
		
		// Test disconnect interrupting tasks
		
		[Test]
		public function testDisconnectFromInterruptingTask():void {
			_task = new InterruptibleStubTask();
			
			addTaskEventListeners( _task );
			
			var interruptingTask:StubTask = new StubTask();
			
			_task.run();
			_task.interruptForTask( interruptingTask );
			
			assertNumEvents( 0, 0, 1 );
			
			assertEquals( _task.interruptingTask.uniqueID, interruptingTask.uniqueID );
			
			_task.disconnectFromInterruptingTask();
			
			assertNull( _task.interruptingTask );
			
			interruptingTask.doTaskComplete();
			
			assertFalse( _task.running );
			
			assertNumEvents( 0, 0, 1 );
		}
		
		// Test resume after error
		
		[Test]
		public function test_runningAfterError_eventHandlersCalled():void {
			var task:Task = new StubTask();
			
			addTaskEventListeners( task );
			
			task.run();
			
			assertEquals( 1, _numStartedEvents );
			
			task.doTaskError();
			
			assertEquals( 1, _numStartedEvents, _numErrorEvents );
			
			task.run();
			
			assertEquals( 2, _numStartedEvents );
			assertEquals( 1, _numErrorEvents );
			
			task.doTaskComplete();
			
			assertEquals( 2, _numStartedEvents );
			assertEquals( 1, _numErrorEvents, _numErrorEvents );
		}
		
		[Test]
		public function test_runningAfterError_handlerMethodsCalled():void {
			var task:Task = new StubTask();
			
			addTaskHandlers( task );
			
			task.run();
			
			assertEquals( 1, _numStartedEvents );
			
			task.doTaskError();
			
			assertEquals( 1, _numStartedEvents, _numErrorEvents );
			
			task.run();
			
			assertEquals( 2, _numStartedEvents );
			assertEquals( 1, _numErrorEvents );
			
			task.doTaskComplete();
			
			assertEquals( 2, _numStartedEvents );
			assertEquals( 1, _numErrorEvents, _numErrorEvents );
		}
	}
}