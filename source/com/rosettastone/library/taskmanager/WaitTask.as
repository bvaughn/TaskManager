package com.rosettastone.library.taskmanager {
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	/**
	 * Task that delays for a specified time before completion.
	 * 
	 * This task supports interruption as well as resume.
	 * Upon resuming an interrupted Wait this Task can either re-start the Timer at the beginning or resume from the interrupted point.
	 * This behavior can be controlled via the constructor parameter "restartTimerAfterInterruption".
	 */
	public class WaitTask extends InterruptibleTask {
		
		private var _duration:int;
		private var _ellapsedTimeAtPointOfInterruption:int;
		private var _restartTimerAfterInterruption:Boolean;
		private var _timer:Timer;
		private var _timerStartTime:int;
		
		/**
		 * Constructor.
		 * 
		 * @param duration Number of milliseconds Task should wait before completing
		 * @param restartTimerAfterInterruption Specifies the resume-after-interruption behavior
		 */
		public function WaitTask( duration:int = 0, restartTimerAfterInterruption:Boolean = true, taskIdentifier:String = null ) {
			super( taskIdentifier );
			
			_duration = duration;
			_restartTimerAfterInterruption = restartTimerAfterInterruption;
			
			_ellapsedTimeAtPointOfInterruption = 0;
			_timerStartTime = 0;
		}
		
		/**
		 * Number of milliseconds Task should wait before completing.
		 */
		public function get duration():int {
			return _duration;
		}
		
		/**
		 * @inheritDocs
		 */
		override protected function customInterrupt():void {
			if ( _timer ) {
				_ellapsedTimeAtPointOfInterruption = getTimer() - _timerStartTime;
				
				_timer.removeEventListener( TimerEvent.TIMER_COMPLETE, onTimerComplete );
				_timer.stop();
				_timer = null;
			}
		}
		
		/**
		 * @inheritDocs
		 */
		override protected function customRun():void {
			var timerDuration:int = _duration;
			
			if ( _ellapsedTimeAtPointOfInterruption > 0 && !_restartTimerAfterInterruption ) {
				timerDuration = _duration - _ellapsedTimeAtPointOfInterruption;
			}
			
			_timerStartTime = getTimer();
			
			// TRICKY: In the event of a composite task being paused and resumed at the point when this wait task had completed,
			// This value will end up being negative which would result in a RangeError being thrown.
			// TODO: Not sure if the above comment is still true or valid.
			// Once a Task completes it should not be able to be re-run via the run() method (nor should the parent composite task try).
			if ( timerDuration > 0 ) {
				_timer = new Timer( timerDuration, 1 );
				_timer.addEventListener( TimerEvent.TIMER_COMPLETE, onTimerComplete );
				_timer.start();
				
			} else {
				taskComplete();
			}
		}
		
		/*
		 * Event handlers
		 */
		
		private function onTimerComplete( event:TimerEvent ):void {
			_timer.removeEventListener( TimerEvent.TIMER_COMPLETE, onTimerComplete );
			
			taskComplete();
		}
	}
}