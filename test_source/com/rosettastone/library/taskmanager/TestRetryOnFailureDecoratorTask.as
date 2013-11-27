package com.rosettastone.library.taskmanager {
	import flexunit.framework.BetterTestCase;
	
	use namespace TaskPrivateNamespace;
	
	public class TestRetryOnFailureDecoratorTask extends BetterTestCase {
		
		private var _decoratedStubTask:StubTask;
		private var _taskThatRequiresInternetConnection:RetryOnFailureDecoratorTask;
		
		[Setup]
		override public function setUp():void {
			_decoratedStubTask = new StubTask();
			_taskThatRequiresInternetConnection = new RetryOnFailureDecoratorTask( _decoratedStubTask );
		}
		
		[Test]
		public function test_simpleRetryBehavior():void {
			for ( var maxRetryAttempts:int = 0; maxRetryAttempts <= 3; maxRetryAttempts++ ) {
				setUp();
				
				RetryOnFailureDecoratorTask.DELAY_BEFORE_RETRYING_IN_MS = 0;
				RetryOnFailureDecoratorTask.MAX_RETRY_ATTEMPTS_BEFORE_ERROR = maxRetryAttempts;
				
				assertEquals( 0, _decoratedStubTask.numTimesStarted, _taskThatRequiresInternetConnection.numTimesStarted );
				
				_taskThatRequiresInternetConnection.run();
				
				assertEquals( 1, _decoratedStubTask.numTimesStarted, _taskThatRequiresInternetConnection.numTimesStarted );
				
				if ( maxRetryAttempts == 0 ) {
					_decoratedStubTask.error();
					
					assertFalse( _taskThatRequiresInternetConnection.running );
					assertTrue( _taskThatRequiresInternetConnection.isErrored );
					
				} else {
					for ( var index:int = 1; index <= maxRetryAttempts + 1; index++ ) {
						_decoratedStubTask.error();
						
						assertEquals( 1, _taskThatRequiresInternetConnection.numTimesStarted, _decoratedStubTask.numTimesStarted );
						
						if ( index <= maxRetryAttempts ) {			
							assertEquals( index, _decoratedStubTask.numTimesReset );
							
							assertTrue( _taskThatRequiresInternetConnection.running );
							assertFalse( _taskThatRequiresInternetConnection.isErrored );
							
						} else {
							assertFalse( _taskThatRequiresInternetConnection.running );
							assertTrue( _taskThatRequiresInternetConnection.isErrored );
						}
					}
				}
			}
		}
		
		[Test]
		public function test_interruptResetsRetryCount():void {
			RetryOnFailureDecoratorTask.DELAY_BEFORE_RETRYING_IN_MS = 0;
			RetryOnFailureDecoratorTask.MAX_RETRY_ATTEMPTS_BEFORE_ERROR = 3;
			
			_taskThatRequiresInternetConnection.run();
			
			assertEquals( 0, _taskThatRequiresInternetConnection.retryAttemptNumber );
			
			_decoratedStubTask.error();
			
			assertEquals( 1, _taskThatRequiresInternetConnection.retryAttemptNumber );
			
			_taskThatRequiresInternetConnection.interrupt();
			
			assertEquals( 0, _taskThatRequiresInternetConnection.retryAttemptNumber );
			
			_taskThatRequiresInternetConnection.run();
			
			_decoratedStubTask.error();
			
			assertEquals( 1, _taskThatRequiresInternetConnection.retryAttemptNumber );
		}
		
		[Test]
		public function test_decoratedTaskCompletesWhileInterrupted():void {
			_taskThatRequiresInternetConnection.run();
			_taskThatRequiresInternetConnection.interrupt();
			
			assertFalse( _decoratedStubTask.isInterrupted );
			assertTrue( _taskThatRequiresInternetConnection.isInterrupted );
			
			_decoratedStubTask.complete();
			
			assertTrue( _decoratedStubTask.isComplete );
			assertFalse( _taskThatRequiresInternetConnection.isComplete );
			
			_taskThatRequiresInternetConnection.run();
			
			assertFalse( _decoratedStubTask.running );
			assertTrue( _taskThatRequiresInternetConnection.isComplete );
		}
		
		[Test]
		public function test_interruptibleDecoratedTask_errorsWhileInterrupted_properlyResumes():void {
			var stubTask:InterruptibleStubTask = new InterruptibleStubTask();
			
			_taskThatRequiresInternetConnection = new RetryOnFailureDecoratorTask( stubTask );
			
			_taskThatRequiresInternetConnection.run();
			_taskThatRequiresInternetConnection.interrupt();
			
			assertTrue( _taskThatRequiresInternetConnection.isInterrupted, stubTask.isInterrupted );
			
			stubTask.run();
			stubTask.error();
			
			assertTrue( stubTask.isErrored );
			assertFalse( _taskThatRequiresInternetConnection.isErrored );
			
			_taskThatRequiresInternetConnection.run();
			
			assertTrue( stubTask.running, _taskThatRequiresInternetConnection.running );
			
			stubTask.complete();
			
			assertTrue( stubTask.isComplete, _taskThatRequiresInternetConnection.isComplete );
		}
		
		[Test]
		public function test_nonInterruptibleDecoratedTask_errorsWhileInterrupted_properlyResumes():void {
			var numTimesInterruptibleDecoratorTaskStarted:int = 0;
			
			// RetryOnFailureDecoratorTask decorates an InterruptibleDecoratorTask which itself decorates the StubTask (since it's not interruptible).
			// This IInterruptibleTask wrapper is automatically added by RetryOnFailureDecoratorTask for tasks that are not interruptible.
			var interruptibleDecoratorTask:InterruptibleDecoratorTask = _taskThatRequiresInternetConnection.decoratedTask as InterruptibleDecoratorTask;
			interruptibleDecoratorTask.withStartedHandler(
				function():void {
					numTimesInterruptibleDecoratorTaskStarted++;
				} );
			
			_taskThatRequiresInternetConnection.run();
			_taskThatRequiresInternetConnection.interrupt();
			
			assertEquals( 1, interruptibleDecoratorTask.numTimesStarted, interruptibleDecoratorTask.numTimesInterrupted );
			
			assertFalse( _decoratedStubTask.isInterrupted );
			assertTrue( interruptibleDecoratorTask.isInterrupted, _taskThatRequiresInternetConnection.isInterrupted );
			
			_decoratedStubTask.error();
			
			assertTrue( _decoratedStubTask.isErrored );
			assertFalse( _taskThatRequiresInternetConnection.isErrored, interruptibleDecoratorTask.isErrored );
			
			RetryOnFailureDecoratorTask.DELAY_BEFORE_RETRYING_IN_MS = 0;
			
			// At this point, restarting the RetryOnFailureDecoratorTask should cause the InterruptibleDecoratorTask to process the pending error event.
			// The RetryOnFailureDecoratorTask will pick up on this error and automatically retry (given that's the nature of the task).
			_taskThatRequiresInternetConnection.run();
			
			assertEquals( 2, _taskThatRequiresInternetConnection.numTimesStarted );
			assertEquals( 3, numTimesInterruptibleDecoratorTaskStarted );
			assertEquals( 1, interruptibleDecoratorTask.numTimesStarted ); // Task reset() by RetryOnFailureDecoratorTask
			
			assertTrue( _taskThatRequiresInternetConnection.running, interruptibleDecoratorTask.running, _decoratedStubTask.running );
		}
	}
}