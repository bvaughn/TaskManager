package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.events.TaskEvent;
	
	import flexunit.framework.TestCase;
	
	import org.flexunit.asserts.fail;
	
	public class TestInterruptibleCompositeTask extends AbstractTaskTestCase {
		
		private var _interruptibleCompositeTask:InterruptibleCompositeTask;
		
		[Before]
		override public function setUp():void {
			super.setUp();
			
			_interruptibleCompositeTask = new InterruptibleCompositeTask();
		}
		
		[Test]
		public function testInterruptibleCompositeTaskErrorsIfGivenNonInterruptibleChildTasksAsConstructorParam():void {
			var errorThrown:Boolean = false;
			
			try {
				_interruptibleCompositeTask =
					new InterruptibleCompositeTask(
						[ new Task() ] );
				
			} catch ( error:Error ) {
				errorThrown = true;
			}
			
			assertTrue( errorThrown );
		}
		
		[Test]
		public function testInterruptibleCompositeAcceptsFunctionsAsConstructorParam():void {
			new InterruptibleCompositeTask( [ function():void {} ] );
		}
		
		[Test]
		public function testInterruptibleCompositeAcceptsFunctions():void {
			new InterruptibleCompositeTask().addFunction( function():void {} );
		}
		
		[Test]
		public function testInterruptibleCompositeTaskHandlesSynchronousChildTasks():void {
			var closure:Function =
				function():void {
					// No-op
				};
			
			_interruptibleCompositeTask = new InterruptibleCompositeTask();
			_interruptibleCompositeTask.addSynchronousTask(
				new SynchronousTaskWithClosure( closure ) );
			_interruptibleCompositeTask.run();
			
			assertFalse( _interruptibleCompositeTask.running );
			assertTrue( _interruptibleCompositeTask.isComplete );
		}
		
		[Test]
		public function testInterruptibleCompositeTaskHandlesSimplePauseAndResume():void {
			var numStartedEvents:int = 0;
			
			var stubTask:InterruptibleStubTask = new InterruptibleStubTask();
			stubTask.addEventListener(
				TaskEvent.STARTED,
				function( event:TaskEvent ):void {
					numStartedEvents++;
					
					if ( numStartedEvents == 2 ) {
						stubTask.complete();
					}
				} );
			
			_interruptibleCompositeTask = new InterruptibleCompositeTask( [ stubTask ] );
			_interruptibleCompositeTask.run();
			
			_interruptibleCompositeTask.interrupt();
			
			assertFalse( _interruptibleCompositeTask.running );
			assertFalse( _interruptibleCompositeTask.isComplete );
			assertEquals( 1, numStartedEvents );
			
			_interruptibleCompositeTask.run();
			
			assertFalse( _interruptibleCompositeTask.running );
			assertTrue( _interruptibleCompositeTask.isComplete );
			assertEquals( 2, numStartedEvents );
		}
		
		[Test]
		public function testInterruptibleCompositeTaskHandlesPauseAndResumeWhenSomeTasksHaveCompleted():void {
			var numStubTask1StartedEvents:int = 0;
			var numStubTask2StartedEvents:int = 0;
			
			var stubTask1:InterruptibleStubTask = new InterruptibleStubTask();
			stubTask1.addEventListener(
				TaskEvent.STARTED,
				function( event:TaskEvent ):void {
					numStubTask1StartedEvents++;
					
					stubTask1.complete();
				} );
			
			var stubTask2:InterruptibleStubTask = new InterruptibleStubTask();
			stubTask2.addEventListener(
				TaskEvent.STARTED,
				function( event:TaskEvent ):void {
					numStubTask2StartedEvents++;
					
					if ( numStubTask2StartedEvents == 2 ) {
						stubTask2.complete();
					}
				} );
			
			_interruptibleCompositeTask = new InterruptibleCompositeTask( [ stubTask1, stubTask2 ] );
			_interruptibleCompositeTask.run();
			_interruptibleCompositeTask.interrupt();
			
			assertFalse( _interruptibleCompositeTask.running );
			assertFalse( _interruptibleCompositeTask.isComplete );
			assertEquals( 1, numStubTask1StartedEvents, numStubTask2StartedEvents );
			assertTrue( stubTask1.isComplete );
			assertFalse( stubTask2.isComplete );
			
			_interruptibleCompositeTask.run();
			
			assertFalse( _interruptibleCompositeTask.running );
			assertTrue( _interruptibleCompositeTask.isComplete );
			assertEquals( 1, numStubTask1StartedEvents );
			assertEquals( 2, numStubTask2StartedEvents );
			assertTrue( stubTask1.isComplete );
			assertTrue( stubTask2.isComplete );
		}
		
		// Tests pertaining to adding/removing Tasks at runtime are below this line.
		
		[Test]
		public function testAddingTaskToRunningParallelCompositeTask():void {
			var stubTask1:InterruptibleStubTask = new InterruptibleStubTask();
			var stubTask2:InterruptibleStubTask = new InterruptibleStubTask();
			
			_interruptibleCompositeTask = new InterruptibleCompositeTask( [ stubTask1 ], true );
			_interruptibleCompositeTask.run();
			
			assertTrue( stubTask1.running );
			assertFalse( stubTask2.running );
			
			_interruptibleCompositeTask.addTask( stubTask2 );
			
			assertTrue( stubTask1.running );
			assertTrue( stubTask2.running );
			
			stubTask1.complete();
			
			assertFalse( _interruptibleCompositeTask.isComplete );
			
			stubTask2.complete();
			
			assertTrue( _interruptibleCompositeTask.isComplete );
		}
		
		[Test]
		public function testAddingTaskToRunningSerialCompositeTask():void {
			var stubTask1:InterruptibleStubTask = new InterruptibleStubTask();
			var stubTask2:InterruptibleStubTask = new InterruptibleStubTask();
			
			_interruptibleCompositeTask = new InterruptibleCompositeTask( [ stubTask1 ], false );
			_interruptibleCompositeTask.run();
			
			assertTrue( stubTask1.running );
			assertFalse( stubTask2.running );
			
			_interruptibleCompositeTask.addTask( stubTask2 );
			
			assertTrue( stubTask1.running );
			assertFalse( stubTask2.running );
			
			stubTask1.complete();
			
			assertFalse( _interruptibleCompositeTask.isComplete );
			
			assertFalse( stubTask1.running );
			assertTrue( stubTask2.running );
			
			stubTask2.complete();
			
			assertTrue( _interruptibleCompositeTask.isComplete );
		}
		
		// Resume after error behavior
		
		[Test]
		public function test_resumeAfterError_errorsBeforeTaskInterrupt_resumesAsExpectsByRetryingErroredTasks_parallelComposite():void {
			var stubTask1:InterruptibleStubTask = new InterruptibleStubTask();
			var stubTask2:InterruptibleStubTask = new InterruptibleStubTask();
			var stubTask3:InterruptibleStubTask = new InterruptibleStubTask();
			var stubTask4:InterruptibleStubTask = new InterruptibleStubTask();
			
			_interruptibleCompositeTask = new InterruptibleCompositeTask( [ stubTask1, stubTask2, stubTask3, stubTask4 ], true );
			_interruptibleCompositeTask.run();
			
			assertEquals( 1, stubTask1.numTimesStarted, stubTask2.numTimesStarted, stubTask3.numTimesStarted, stubTask4.numTimesStarted );
			
			stubTask2.error();
			stubTask4.complete();
			
			assertTrue( _interruptibleCompositeTask.running );
			
			_interruptibleCompositeTask.interrupt();
			
			assertTrue( _interruptibleCompositeTask.isInterrupted, stubTask1.isInterrupted, stubTask3.isInterrupted );
			
			_interruptibleCompositeTask.run();
			
			assertEquals( 2, stubTask1.numTimesStarted, stubTask2.numTimesStarted, stubTask3.numTimesStarted );
			assertEquals( 1, stubTask4.numTimesStarted );
			
			stubTask1.complete();
			stubTask2.complete();
			stubTask3.complete();
			
			assertTrue( _interruptibleCompositeTask.isComplete );
			assertEquals( 0, _interruptibleCompositeTask.numTimesErrored );
			assertEquals( 1, _interruptibleCompositeTask.numTimesCompleted );
		}
	}
}