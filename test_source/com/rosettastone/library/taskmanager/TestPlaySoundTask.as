package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.events.TaskEvent;
	
	import flash.events.TimerEvent;
	import flash.media.Sound;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	/**
	 * 
	 */
	public class TestPlaySoundTask extends AbstractTaskTestCase {
		
		[Embed(source="/assets/quarter_second_silence.mp3")]
		private static const EMBEDDED_TEST_SOUND:Class;
		
		private var _playSoundTask:PlaySoundTask;
		private var _timer:Timer;
		
		[Before]
		override public function setUp():void {
			super.setUp();
		}
		
		[After]
		override public function tearDown():void {
			if ( _playSoundTask && _playSoundTask.running ) {
				_playSoundTask.interrupt();
			}
			
			if ( _timer && _timer.running ) {
				_timer.stop();
			}
		}
		
		[Test]
		public function testNullSoundCausesError():void {
			_playSoundTask = new PlaySoundTask( null );
			
			addTaskEventListeners( _playSoundTask );
			
			_playSoundTask.run();
			
			assertNumEvents( 0, 1, 0 );
		}
		
		[Test]
		public function testEmptySoundCausesError():void {
			_playSoundTask = new PlaySoundTask( new Sound() );
			
			addTaskEventListeners( _playSoundTask );
			
			_playSoundTask.run();
			
			assertNumEvents( 0, 1, 0 );
		}
		
		[Test]
		public function testPlaySound():void {
			var startTime:int = getTimer();
			
			var taskCompleteHandler:Function =
				function( event:TaskEvent ):void {
					assertTrue( getTimer() - startTime >= 250 );
				};
			
			_playSoundTask = new PlaySoundTask( new EMBEDDED_TEST_SOUND() as Sound );
			_playSoundTask.addEventListener(
				TaskEvent.COMPLETE,
				addAsync( taskCompleteHandler, 1000 ) );
			_playSoundTask.run();
		}
		
		[Test]
		public function testPlaySoundWithInterruptAndRestart():void {
			var startTime:int = getTimer();
			var interruptTime:int;
			var resumeTime:int;
			
			var taskCompleteHandler:Function =
				function( event:TaskEvent ):void {
					_timer.removeEventListener( TimerEvent.TIMER, timerHandler );
					
					var completedTime:int = getTimer();
					var duration:int = ( interruptTime - startTime ) + ( completedTime - resumeTime );
					
					assertTrue( "Expected 250ms duration but found " + duration, duration >= 250 );
				};
			
			var timerHandler:Function =
				function( event:TimerEvent ):void {
					switch ( _timer.currentCount ) {
						case 1:
							interruptTime = getTimer();
							
							_playSoundTask.interrupt();
							break;
						case 2:
							resumeTime = getTimer();
							
							_playSoundTask.run();
							break;
					}
				};
			
			_timer = new Timer( 100, 2 );
			_timer.addEventListener( TimerEvent.TIMER, timerHandler );
			_timer.start();
			
			_playSoundTask = new PlaySoundTask( new EMBEDDED_TEST_SOUND() as Sound, false );
			_playSoundTask.addEventListener(
				TaskEvent.COMPLETE,
				addAsync( taskCompleteHandler, 750 ) );
			_playSoundTask.run();
		}
		
		[Test]
		public function testPlaySoundWithInterrupt():void {
			var sound:Sound = new EMBEDDED_TEST_SOUND() as Sound;
			
			var timerHandler:Function =
				function( event:TimerEvent ):void {
					switch ( _timer.currentCount ) {
						case 1:
							_playSoundTask.interrupt();
							break;
					}
				};
			
			var timerCompleteHandler:Function =
				function( event:TimerEvent ):void {
					assertTrue( true );
				};
			
			_timer = new Timer( 100, 5 );
			_timer.addEventListener( TimerEvent.TIMER_COMPLETE, addAsync( timerCompleteHandler, 750 ) );
			_timer.addEventListener( TimerEvent.TIMER, timerHandler );
			_timer.start();
			
			_playSoundTask = new PlaySoundTask( sound, true );
			_playSoundTask.run();
		}
		
		[Test]
		public function testPlaySoundWithInterruptAndRestartFromBeginning():void {
			var startTime:int = getTimer();
			var interruptTime:int;
			var resumeTime:int;
			
			var taskCompleteHandler:Function =
				function( event:TaskEvent ):void {
					_timer.removeEventListener( TimerEvent.TIMER, timerHandler );
					
					var completedTime:int = getTimer();
					var durationA:int = ( interruptTime - startTime ) + ( completedTime - resumeTime );
					var durationB:int = ( completedTime - resumeTime );
					
					// Time restarted, so the total running time should well exceed the WaitTask's duration
					assertTrue( "Expected 350ms duration but found " + durationA, durationA >= 350 );
					assertTrue( "Expected 250ms duration but found " + durationB, durationB >= 250 );
				};
			
			var timerHandler:Function =
				function( event:TimerEvent ):void {
					switch ( _timer.currentCount ) {
						case 1:
							interruptTime = getTimer();
							
							_playSoundTask.interrupt();
							break;
						case 2:
							resumeTime = getTimer();
							
							_playSoundTask.run();
							break;
					}
				};
			
			_timer = new Timer( 100, 2 );
			_timer.addEventListener( TimerEvent.TIMER, timerHandler );
			_timer.start();
			
			_playSoundTask = new PlaySoundTask( new EMBEDDED_TEST_SOUND() as Sound, true );
			_playSoundTask.addEventListener(
				TaskEvent.COMPLETE,
				addAsync( taskCompleteHandler, 750 ) );
			_playSoundTask.run();
		}
	}
}