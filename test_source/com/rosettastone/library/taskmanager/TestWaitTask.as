package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.events.TaskEvent;
	
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import flexunit.framework.TestCase;
	
	import org.flexunit.async.Async;
	
	/**
	 * Tests the WaitTask and its interrupt/resume behavior.
	 */
	public class TestWaitTask extends AbstractTaskTestCase {
		
		private var _timer:Timer;
		private var _waitTask:WaitTask;
		
		[Before]
		override public function setUp():void {
			super.setUp();
			
			_waitTask = new WaitTask();
		}
		
		[After]
		override public function tearDown():void {
			if ( _waitTask && _waitTask.running ) {
				_waitTask.interrupt();
			}
			
			if ( _timer && _timer.running ) {
				_timer.stop();
			}
		}
		
		[Test]
		public function testWaitTaskWaitsForTheSpecifiedTime():void {
			var startTime:int = getTimer();
			
			var completeHandler:Function =
				function( event:TaskEvent ):void {
					var endTime:int = getTimer();
					var duration:int = endTime - startTime;
					
					// We can't be too exact here.
					// Flash player has different framerates depending on a variety of factors.
					assertTrue( "Expected 500ms duration but found " + duration, duration >= 500 );
				};
			
			_waitTask = new WaitTask( 500 );
			_waitTask.addEventListener(
				TaskEvent.COMPLETE,
				addAsync( completeHandler, 1000 ) );
			_waitTask.run();
		}
		
		[Test]
		public function testPauseAndResumeWithRestartWaitTask():void {
			var startTime:int = getTimer();
			var interruptTime:int;
			var resumeTime:int;
			var completedTime:int;
			
			var timerHandler:Function =
				function( event:TimerEvent ):void {
					switch ( _timer.currentCount ) {
						case 1: // Timer: 200 ms, WaitTask: 200 ms 
							assertTrue( _waitTask.running );
							
							interruptTime = getTimer();
							
							_waitTask.interrupt();
							break;
						case 2: // Timer: 400 ms, WaitTask: 0 ms (restarted)
							resumeTime = getTimer();
							
							_waitTask.run();
							
							assertTrue( _waitTask.running );
							break;
						case 3: // Timer: 600 ms, WaitTask: 200 ms
							assertTrue( _waitTask.running );
							assertFalse( _waitTask.isComplete );
							break;
						case 4: // Timer: 800 ms, WaitTask: 300 ms (should be complete)
							assertFalse( _waitTask.running );
							assertTrue( _waitTask.isComplete );
							break;
					}
				};
			
			var timerCompleteHandler:Function =
				function( event:TimerEvent ):void {
					_timer.removeEventListener( TimerEvent.TIMER, timerHandler );
					
					var durationA:int = ( interruptTime - startTime ) + ( completedTime - resumeTime );
					var durationB:int = ( completedTime - resumeTime );
					
					// Time restarted, so the total running time should well exceed the WaitTask's duration
					assertTrue( "Expected 500ms duration but found " + durationA, durationA >= 500 );
					assertTrue( "Expected 300ms duration but found " + durationB, durationB >= 300 );
				};
			
			var taskCompleteHandler:Function =
				function( event:TaskEvent ):void {
					_waitTask.removeEventListener( TaskEvent.COMPLETE, taskCompleteHandler );
					
					completedTime = getTimer();
				};
			
			_timer = new Timer( 200, 4 );
			_timer.addEventListener( TimerEvent.TIMER, timerHandler );
			_timer.addEventListener( TimerEvent.TIMER_COMPLETE, addAsync( timerCompleteHandler, 2000 ) );
			_timer.start();
			
			_waitTask = new WaitTask( 300, true );
			_waitTask.addEventListener( TaskEvent.COMPLETE, taskCompleteHandler );
			_waitTask.run();
		}
		
		[Test]
		public function testPauseAndResumeWithoutRestartWaitTask():void {
			var startTime:int = getTimer();
			var interruptTime:int;
			var resumeTime:int;
			var completedTime:int;
			
			var timerHandler:Function =
				function( event:TimerEvent ):void {
					switch ( _timer.currentCount ) {
						case 1: // Timer: 250 ms, WaitTask: 250 ms 
							assertTrue( _waitTask.running );
							
							interruptTime = getTimer();
							
							_waitTask.interrupt();
							break;
						case 2: // Timer: 500 ms, WaitTask: 250 ms
							assertFalse( _waitTask.running );
							assertFalse( _waitTask.isComplete );
							break;
						case 3: // Timer: 750 ms, WaitTask: 250 ms
							assertFalse( _waitTask.running );
							assertFalse( _waitTask.isComplete );
							break;
						case 4: // Timer: 1000 ms, WaitTask: 250 ms
							resumeTime = getTimer();
							
							_waitTask.run();
							
							assertTrue( _waitTask.running );
							break;
						case 5: // Timer: 1250 ms, WaitTask: 500 ms
							assertTrue( _waitTask.running );
							assertFalse( _waitTask.isComplete );
							break;
						case 6: // Timer: 1500 ms, WaitTask: 600 ms (should be complete)
							assertFalse( _waitTask.running );
							assertTrue( _waitTask.isComplete );
							break;
					}
				};
			
			var timerCompleteHandler:Function =
				function( event:TimerEvent ):void {
					var duration:int = ( interruptTime - startTime ) + ( completedTime - resumeTime );
					
					assertTrue( "Expected 500ms duration but found " + duration, duration >= 500 );
				};
			
			var taskCompleteHandler:Function =
				function( event:TaskEvent ):void {
					_timer.removeEventListener( TimerEvent.TIMER, timerHandler );
					
					_waitTask.removeEventListener( TaskEvent.COMPLETE, taskCompleteHandler );
					
					completedTime = getTimer();
				};
			
			_timer = new Timer( 250, 6 );
			_timer.addEventListener( TimerEvent.TIMER, timerHandler );
			_timer.addEventListener( TimerEvent.TIMER_COMPLETE, addAsync( timerCompleteHandler, 2000 ) );
			_timer.start();
			
			_waitTask = new WaitTask( 600, false );
			_waitTask.addEventListener( TaskEvent.COMPLETE, taskCompleteHandler );
			_waitTask.run();
		}
	}
}