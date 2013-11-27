package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.events.TaskEvent;
	
	import flash.events.ProgressEvent;
	
	/**
	 * Decorates a non-interruptible Task and adds interruptible-like behavior.
	 * This task does not actually stop and resume the decorated Task,
	 * But it does prevent ERROR or COMPLETE events from being dispatched when in an interrupted state.
	 * Should ERROR or COMPLETE occur while interrupted they will be re-dispatched upon resume.
	 * 
	 * This Task-type also re-dispatches any ProgressEvents dispatched by the decorated Task.
	 */
	public class InterruptibleDecoratorTask extends InterruptibleTask implements IDecoratorTask {
		
		private var _decoratedTask:ITask;
		private var _decoratedTaskEvent:TaskEvent;
		private var _progressEvents:Array;
		
		public function InterruptibleDecoratorTask( decoratedTask:ITask, taskIdentifier:String = null ) {
			super( taskIdentifier );
			
			_decoratedTask = decoratedTask;
			
			_progressEvents = new Array();
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
		override public function get taskIdentifier():String {
			return decoratedTask ? decoratedTask.taskIdentifier : null;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get numInternalOperations():int {
			return decoratedTask ? decoratedTask.numInternalOperations : 0;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get numInternalOperationsCompleted():int {
			return decoratedTask ? decoratedTask.numInternalOperationsCompleted : 0;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customInterrupt():void {
			// Do not interrupt the (non-interruptible) decorated Task.
			// Instead, we'll queue up its events and pass them along once we're resumed.
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customRun():void {
			while ( _progressEvents.length > 0 ) {
				dispatchEvent(
					_progressEvents.shift() );
			}
			
			if ( !_decoratedTask.running && !_decoratedTask.isComplete && !_decoratedTask.isErrored ) {
				_decoratedTask.addEventListener( TaskEvent.COMPLETE, onDecoratedTaskComplete );
				_decoratedTask.addEventListener( TaskEvent.ERROR, onDecoratedTaskError );
				_decoratedTask.addEventListener( ProgressEvent.PROGRESS, onDecoratedTaskProgress );
				_decoratedTask.run();
				
			} else if ( _decoratedTaskEvent ) {
				if ( _decoratedTaskEvent.type == TaskEvent.COMPLETE ) {
					taskComplete( _decoratedTaskEvent.message, _decoratedTaskEvent.data );
				} else if ( _decoratedTaskEvent.type == TaskEvent.ERROR ) {
					taskError( _decoratedTaskEvent.message, _decoratedTaskEvent.data );
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customReset():void {
			if ( decoratedTask ) {
				decoratedTask.reset();
			}
		}
		
		/*
		* Event handlers
		*/
		
		private function onDecoratedTaskComplete( event:TaskEvent ):void {
			_decoratedTask.removeEventListener( TaskEvent.COMPLETE, onDecoratedTaskComplete );
			_decoratedTask.removeEventListener( TaskEvent.ERROR, onDecoratedTaskError );
			_decoratedTask.removeEventListener( ProgressEvent.PROGRESS, onDecoratedTaskProgress );
			
			if ( isInterrupted ) {
				_decoratedTaskEvent = event;
			} else {
				taskComplete( event.message, event.data );
			}
		}
		
		private function onDecoratedTaskError( event:TaskEvent ):void {
			_decoratedTask.removeEventListener( TaskEvent.COMPLETE, onDecoratedTaskComplete );
			_decoratedTask.removeEventListener( TaskEvent.ERROR, onDecoratedTaskError );
			_decoratedTask.removeEventListener( ProgressEvent.PROGRESS, onDecoratedTaskProgress );
			
			if ( isInterrupted ) {
				_decoratedTaskEvent = event;
			} else {
				taskError( event.message, event.data );
			}
		}
		
		private function onDecoratedTaskProgress( event:ProgressEvent ):void {
			if ( isInterrupted ) {
				_progressEvents.push( event );
			} else {
				dispatchEvent( event );
			}
		}
	}
}