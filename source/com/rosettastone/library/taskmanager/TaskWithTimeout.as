package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.events.TaskEvent;
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	/**
	 * Decorates a Task and enforces a max-execution time limit.
	 * If specified time interval elapses before the decorated Task has complete it is considered to be an error.
	 * The decorated Task will be interrupted (if possible) in that event.
	 */
	public class TaskWithTimeout extends InterruptibleTask implements IDecoratorTask {
		
		private var _decoratedTask:IInterruptibleTask;
		private var _timer:Timer;
		private var _timeout:int;
		
		public function TaskWithTimeout( taskToDecorate:ITask, timeout:int = 1000, taskIdentifier:String = null ) {
			super( taskIdentifier );
			
			_decoratedTask =
				taskToDecorate is IInterruptibleTask ?
					taskToDecorate as IInterruptibleTask :
					new InterruptibleDecoratorTask( taskToDecorate );
			_timeout = timeout;
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
			_timer.removeEventListener( TimerEvent.TIMER_COMPLETE, onTimerComplete );
			_timer.stop();
			
			_decoratedTask.removeEventListener( TaskEvent.COMPLETE, onDecoratedTaskComplete );
			_decoratedTask.removeEventListener( TaskEvent.ERROR, onDecoratedTaskError );
			_decoratedTask.interrupt();
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customRun():void {
			_timer = new Timer( _timeout, 1 );
			_timer.addEventListener( TimerEvent.TIMER_COMPLETE, onTimerComplete );
			_timer.start();
			
			_decoratedTask.addEventListener( TaskEvent.COMPLETE, onDecoratedTaskComplete );
			_decoratedTask.addEventListener( TaskEvent.ERROR, onDecoratedTaskError );
			_decoratedTask.run();
		}
		
		/*
		 * Helper methods
		 */
		
		private function tearDown():void {
			_timer.removeEventListener( TimerEvent.TIMER_COMPLETE, onTimerComplete );
			
			if ( _timer.running ) {
				_timer.stop();
			}
			
			_decoratedTask.removeEventListener( TaskEvent.COMPLETE, onDecoratedTaskComplete );
			_decoratedTask.removeEventListener( TaskEvent.ERROR, onDecoratedTaskError );
			
			if ( _decoratedTask.running ) {
				_decoratedTask.interrupt();
			}
		}
		
		/*
		 * Event handlers
		 */
		
		private function onDecoratedTaskComplete( event:TaskEvent ):void {
			tearDown();
			
			taskComplete( event.message, event.data );
		}
		
		private function onDecoratedTaskError( event:TaskEvent ):void {
			tearDown();
			
			taskError( event.message, event.data );
		}
		
		private function onTimerComplete( event:TimerEvent ):void {
			tearDown();
			
			taskError( "Task timed out after " + _timeout + "ms" );
		}
	}
}