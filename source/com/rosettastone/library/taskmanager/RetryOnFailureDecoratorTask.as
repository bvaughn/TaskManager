package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.events.TaskEvent;
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	use namespace TaskPrivateNamespace;
	
	/**
	 * Special Task decorator for Tasks that should be retried on failure.
	 * (For example, this could be useful for Tasks that rely on an internet connection in order to complete.)
	 * 
	 * This task allows its decorated Task to fail a couple of times before bubbling the error.
	 * A small amount of time is allowed to pass between each retry.
	 * This delay allows time for an external monitor to detect a loss of internet connection and pause all Tasks until it is restored.
	 * It also allows for a more graceful handling of occasional HTTP failures.
	 */
	public class RetryOnFailureDecoratorTask extends InterruptibleTask implements IDecoratorTask {
		
		/**
		 * The amount of time to delay before resetting and re-running the decorated Task.
		 * This value should probably only be overriden for unit test purposes.
		 * A value of &lt;= 0 seconds will result in a synchronous retry.
		 */
		TaskPrivateNamespace static var DELAY_BEFORE_RETRYING_IN_MS:int = 1000;
		
		/**
		 * Number of times to reset and re-run the decorated Task.
		 * This value should probably only be overriden for unit test purposes.
		 * A value of &lt;= 0 will cause a single failure to trigger a bubbled failure.
		 */
		TaskPrivateNamespace static var MAX_RETRY_ATTEMPTS_BEFORE_ERROR:int = 5;
		
		private var _decoratedTask:Task;
		private var _retryAttemptNumber:int;
		private var _retryTimer:Timer;
		
		/**
		 * Constructor.
		 * 
		 * @param decoratedTask Ideally this Task should be interruptible; if not it will be wrapped in a InterruptibleDecoratorTask to simulate interruptibility
		 * @param taskIdentifier Optional human-readible Task ID (useful for debug purposes only)
		 */
		public function RetryOnFailureDecoratorTask( decoratedTask:Task, taskIdentifier:String = null ) {
			super( taskIdentifier );
			
			_decoratedTask =
				decoratedTask.interruptible ?
				decoratedTask :
				new InterruptibleDecoratorTask( decoratedTask );
			
			_retryTimer = new Timer( DELAY_BEFORE_RETRYING_IN_MS, 1 );
			_retryTimer.addEventListener( TimerEvent.TIMER_COMPLETE, onRetryTimerComplete );
		}
		
		/**
		 * 
		 */
		override public function get data():* {
			return _decoratedTask ? _decoratedTask.data : null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get decoratedTask():ITask {
			return _decoratedTask;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customInterrupt():void {
			removeDecoratedTaskEventListeners();
			
			_retryAttemptNumber = 0;
			
			if ( _decoratedTask.running ) {
				_decoratedTask.interrupt();
			}
			
			if ( _retryTimer.running ) {
				_retryTimer.stop();
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customRun():void {
			
			// If the Task completed while we weren't listening, we should synchronously complete.
			// Else we should reset it and start again.
			// We don't care about errors that happened during the interruption because they were expected.
			if ( _decoratedTask.isComplete ) {
				handleComplete();
				
			} else {
				executeDecoratedTask();
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customReset():void {
			_retryAttemptNumber = 0;
			
			_decoratedTask.reset();
		}
		
		/*
		 * Hook methods
		 */
		
		/**
		 * Sub-classes may override this method to determine of a failed Task should be retried.
		 * This decision is separate from the normal max-retry counting logic.
		 * By default this function always returns TRUE.
		 */
		protected function shouldFailedTaskBeRetried( failedTask:Task ):Boolean {
			return true;
		}
		
		/*
		 * Helper methods
		 */
		
		private function addDecoratedTaskEventListeners():void {
			_decoratedTask.addEventListener( TaskEvent.COMPLETE, onDecoratedTaskComplete );
			_decoratedTask.addEventListener( TaskEvent.ERROR, onDecoratedTaskError );
		}
		
		private function removeDecoratedTaskEventListeners():void {
			_decoratedTask.removeEventListener( TaskEvent.COMPLETE, onDecoratedTaskComplete );
			_decoratedTask.removeEventListener( TaskEvent.ERROR, onDecoratedTaskError );
		}
		
		private function executeDecoratedTask():void {
			if ( _decoratedTask.isComplete || _decoratedTask.isErrored ) {
				_decoratedTask.reset(); // Not all Tasks properly implement this method, I think.
			}
			
			addDecoratedTaskEventListeners();
			
			// If Task is already/still running from before an interruption then calling run() again will not affect anything.
			// That's fine; in that case we should just wait for the previous execution to complete or error.
			_decoratedTask.run();
		}
		
		private function handleComplete():void {
			taskComplete( _decoratedTask.message, _decoratedTask.data );
		}
		
		private function handleError():void {
			_retryAttemptNumber++;
			
			var retryApproved:Boolean = shouldFailedTaskBeRetried( _decoratedTask );
			
			if ( !retryApproved || _retryAttemptNumber > MAX_RETRY_ATTEMPTS_BEFORE_ERROR ) {
				taskError( _decoratedTask.message, _decoratedTask.data );
			} else if ( DELAY_BEFORE_RETRYING_IN_MS > 0 ) {
				_retryTimer.start();
			} else {
				executeDecoratedTask();
			}
		}
		
		/*
		* Event handlers
		*/
		
		private function onDecoratedTaskComplete( event:TaskEvent ):void {
			if ( isInterrupted ) return;
			
			handleComplete();
		}
		
		private function onDecoratedTaskError( event:TaskEvent ):void {
			if ( isInterrupted ) return;
			
			handleError();
		}
		
		private function onRetryTimerComplete( event:TimerEvent ):void {
			executeDecoratedTask();
		}
		
		/*
		* Unit test accessors
		*/
		
		TaskPrivateNamespace function get retryAttemptNumber():int {
			return _retryAttemptNumber;
		}
	}
}