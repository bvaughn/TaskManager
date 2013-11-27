package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.events.TaskEvent;
	
	/**
	 * Decorates a Task returned by the specified factory method.
	 * This Task does not invoke the provided factory method until it is actually executed.
	 * This allows for just-in-time evaluation of data set by previous Tasks.
	 */
	public class FactoryTask extends InterruptibleTask implements IDecoratorTask {
		
		protected var _args:Array;
		protected var _recreateDecoratedTaskWhenNextRun:Boolean;
		protected var _reexecuteFactoryFunctionAfterError:Boolean;
		protected var _task:IInterruptibleTask;
		protected var _taskFactoryFunction:Function;
		protected var _taskWillBeInterruptible:Boolean;
		protected var _thisObj:*;
		
		/**
		 * Constructor.
		 * 
		 * @param taskFactoryFunction Returns an ITask object
		 * @param thisObj Optional object to which the function is applied.
		 * @param args Optional Array of parameters to be passed to the factory Function.
		 *             If this value is specified a target "thisObj" must be provided as well.
		 * @param taskWillBeInterruptible Task returned by facotry function is interruptible
		 * @param taskIdentifier Semantically meaningful task identifier (useful for automated testing or debugging)
		 */
		public function FactoryTask( taskFactoryFunction:Function,
		                             thisObj:* = null,
		                             args:Array = null,
		                             taskWillBeInterruptible:Boolean = false,
		                             taskIdentifier:String = null ) {
			
			super( taskIdentifier );
			
			_taskWillBeInterruptible = taskWillBeInterruptible;
			_taskFactoryFunction = taskFactoryFunction;
			_thisObj = thisObj;
			_args = args;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get decoratedTask():ITask {
			return _task;
		}
		
		/**
		 * If this FactoryTask is re-run after an error has occurred, this attribute controls whether it:
		 * (a) Reuses the decorated Task initially created during its first run, or
		 * (b) Reexecutes the factory method to create a new decorated Task.
		 * 
		 * By default this value is FALSE, meaning that the decorated task created initially will be reused.
		 */
		public function get reexecuteFactoryFunctionAfterError():Boolean {
			return reexecuteFactoryFunctionAfterError;
		}
		public function setReexecuteFactoryFunctionAfterError( value:Boolean = false ):FactoryTask {
			_reexecuteFactoryFunctionAfterError = value;
			
			return this;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customInterrupt():void {
			if ( _task ) {
				_task.interrupt();
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customReset():void {
			_task = null;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customRun():void {
			if ( !_task || _recreateDecoratedTaskWhenNextRun ) {
				_recreateDecoratedTaskWhenNextRun = false;
				
				var task:ITask;
				
				if ( _thisObj != null ){
					task = _taskFactoryFunction.apply( _thisObj, _args );
				} else {
					task = _taskFactoryFunction();
				}
				
				if ( task is IInterruptibleTask ) {
					_task = task as IInterruptibleTask;
				} else {
					_task = new InterruptibleDecoratorTask( task );
				}
			}
			
			_task.addEventListener( TaskEvent.COMPLETE, onTaskComplete );
			_task.addEventListener( TaskEvent.ERROR, onTaskError );
			_task.addEventListener( TaskEvent.INTERRUPTED, onTaskInterrupted );
			_task.run();
		}
		
		/*
		 * Event handlers
		 */
		
		private function onTaskComplete( event:TaskEvent ):void {
			_task.removeEventListener( TaskEvent.COMPLETE, onTaskComplete );
			_task.removeEventListener( TaskEvent.ERROR, onTaskError );
			_task.removeEventListener( TaskEvent.INTERRUPTED, onTaskInterrupted );
			
			taskComplete( event.message, event.data );
		}
		
		private function onTaskError( event:TaskEvent ):void {
			_task.removeEventListener( TaskEvent.COMPLETE, onTaskComplete );
			_task.removeEventListener( TaskEvent.ERROR, onTaskError );
			_task.removeEventListener( TaskEvent.INTERRUPTED, onTaskInterrupted );
			
			if ( _reexecuteFactoryFunctionAfterError ) {
				_recreateDecoratedTaskWhenNextRun = true;
			}
			
			taskError( event.message, event.data );
		}
		
		private function onTaskInterrupted( event:TaskEvent ):void {
			_task.removeEventListener( TaskEvent.COMPLETE, onTaskComplete );
			_task.removeEventListener( TaskEvent.ERROR, onTaskError );
			_task.removeEventListener( TaskEvent.INTERRUPTED, onTaskInterrupted );
			
			taskInterrupted( event.message, event.data );
		}
	}
}