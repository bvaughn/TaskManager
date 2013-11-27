package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.events.TaskEvent;
	import com.rosettastone.library.taskmanager.events.TaskManagerEvent;
	
	import flash.events.ProgressEvent;
	
	import mx.collections.ArrayCollection;
	
	[Event( name="taskManagerEventComplete", type="com.rosettastone.library.taskmanager.events.TaskManagerEvent" )]
	[Event( name="taskManagerEventError", type="com.rosettastone.library.taskmanager.events.TaskManagerEvent" )]
	[Event( name="taskManagerEventInterrupted", type="com.rosettastone.library.taskmanager.events.TaskManagerEvent" )]
	
	/**
	 * This is an abstract class and should not be instantiated directly.
	 * Instead use one of the following sub-classes: TaskManager, InterruptibleTaskManager
	 */
	public class AbstractTaskManager extends Task {
		
		private static const TASK_STATUS_ACTIVE:String = "active";
		private static const TASK_STATUS_COMPLETED:String = "completed";
		private static const TASK_STATUS_ERRORED:String = "errored";
		private static const TASK_STATUS_INTERRUPTED:String = "interrupted";
		private static const TASK_STATUS_PENDING:String = "pending";
		
		private var _erroredTasks:Array;
		private var _interruptible:Boolean;
		private var _taskIDToDependenciesMap:Object;
		private var _tasks:ArrayCollection;
		
		/**
		 * @private
		 */
		public function AbstractTaskManager( interruptible:Boolean = false ) {
			_interruptible = interruptible;
			
			_taskIDToDependenciesMap = new Object();
			_tasks = new ArrayCollection();
			
			// These events are left around for backwards compatibility only
			addEventListener( TaskEvent.COMPLETE, onTaskManagerComplete, false, -1, true );
			addEventListener( TaskEvent.ERROR, onTaskManagerError, false, -1, true );
		}
		
		/**
		 * There are no pending or active Tasks.
		 * 
		 * @internal
		 * This method is left around for backwards compatibility purposes only.
		 */
		public function get completed():Boolean {
			return isComplete;
		}
		
		/**
		 * Unique error messages from all inner Tasks that failed during execution.
		 */
		public function get errorMessages():Array {
			var returnArray:Array = new Array();
			
			for each ( var task:ITask in _erroredTasks ) {
				if ( returnArray.indexOf( task.message ) < 0 ) {
					returnArray.push( task.message );
				}
			}
			
			return returnArray;
		}
		
		/**
		 * Error datas from all inner Tasks that failed during execution.
		 */
		public function get errorDatas():Array {
			var returnArray:Array = new Array();
			
			for each ( var task:ITask in _erroredTasks ) {
				returnArray.push( task.data );
			}
			
			return returnArray;
		}
		
		/**
		 * Tasks that errored during execution.
		 */
		public function get erroredTasks():Array {
			return _erroredTasks;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get interruptible():Boolean {
			return _interruptible;
		}
		
		/**
		 * Number of Tasks that have successfully completed execution.
		 */
		public function get numCompletedTasks():int {
			var returnValue:int = 0;
			
			for each ( var task:ITask in _tasks ) {
				if ( task.isComplete ) {
					returnValue++;
				}
			}
			
			return returnValue;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get numInternalOperations():int {
			var returnValue:int = 0;
			
			for each ( var task:ITask in _tasks ) {
				returnValue += task.numInternalOperations;
			}
			
			return returnValue;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get numInternalOperationsCompleted():int {
			var returnValue:int = 0;
			
			for each ( var task:ITask in _tasks ) {
				returnValue += task.numInternalOperationsCompleted;
			}
			
			return returnValue;
		}
		
		/**
		 * Number of Tasks to be executed by TaskManager.
		 */
		public function get numTasks():int {
			return _tasks ? _tasks.length : 0;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get synchronous():Boolean {
			for each ( var task:ITask in _tasks ) {
				if ( !task.synchronous ) {
					return false;
				}
			}
			
			return true;
		}
		
		/**
		 * Adds a task to the graph and set its dependencies.
		 * 
		 * If TaskManager is currently running and the specified Taks has invalid dependencies, an ERROR event will be dispatched immediately.
		 *
		 * @param task Task to add to TaskManager
		 * @param dependencies Array of Tasks that newly added Task depends on
		 * 
		 * @throws Error if TaskManager has been configured for interruptible-mode and Task is not either interruptible or synchronous
		 */
		protected function addTaskHelper( task:ITask, dependencies:Array = null ):void {
			if ( _interruptible && !( task is IInterruptibleTask ) && !task.synchronous ) {
				throw Error( "Task must be interruptable or synchronous." );
			}
			
			if ( _tasks.getItemIndex( task ) < 0 ) {
				_tasks.addItem( task );
			}
			
			_taskIDToDependenciesMap[ task.id ] = dependencies;
			
			if ( running ) {
				if ( doesTaskHaveInvalidDependencies( task, new Array() ) ) {
					dispatchEvent(
						new TaskManagerEvent(
							TaskManagerEvent.ERROR,
							task,
							"One or more Tasks have invalid dependencies." ) );
				}
				
				runAllReadyTasks();
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override public function interrupt():Boolean {
			if ( !interruptible || isInterrupted ) {
				return false;
			}
			
			taskInterrupted(); // Updates interrupted state and dispatches events
			
			for each ( var task:ITask in _tasks ) {
				if ( task.isRunning ) {
					task.removeEventListener( TaskEvent.COMPLETE, onTaskComplete );
					task.removeEventListener( TaskEvent.ERROR, onTaskError );
					task.removeEventListener( ProgressEvent.PROGRESS, onTaskProgress );
					( task as IInterruptibleTask ).interrupt();
				}
			}
			
			return true;
		}
		
		/**
		 * Removes a task from the task manager.
		 * 
		 * If the TaskManager is running and this operation unblocks any of the remaining Tasks, they will be executed as a result of this removal.
		 *
		 * @param taskToRemove The task to remove
		 */
		protected function removeTaskHelper( taskToRemove:ITask ):void {
			taskToRemove.removeEventListener( TaskEvent.COMPLETE, onTaskComplete );
			taskToRemove.removeEventListener( TaskEvent.ERROR, onTaskError );
			taskToRemove.removeEventListener( ProgressEvent.PROGRESS, onTaskProgress );
			
			if ( _tasks.getItemIndex( taskToRemove ) >= 0 ) {
				_tasks.removeItemAt( _tasks.getItemIndex( taskToRemove ) );
			}
			
			delete _taskIDToDependenciesMap[ taskToRemove.id ];
			
			// TODO: Check for and remove any orphaned dependencies?
			
			if ( running ) {
				for each ( var remainingTask:ITask in _tasks ) {
					var dependencies:Array = _taskIDToDependenciesMap[ remainingTask.id ] as Array;
					
					if ( dependencies && dependencies.indexOf( taskToRemove ) >= 0 ) {
						dependencies.splice(
							dependencies.indexOf( taskToRemove ), 1 );
					}
				}
				
				checkForCompletionOrRunAllReadyTasks();
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customReset():void {
			_erroredTasks = new Array();
			_taskIDToDependenciesMap = new Object();
			
			_tasks.removeAll();
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customRun():void {
			_erroredTasks = new Array();
			
			for each ( var task:ITask in _tasks ) {
				if ( doesTaskHaveInvalidDependencies( task, new Array() ) ) {
					dispatchEvent(
						new TaskManagerEvent(
							TaskManagerEvent.ERROR,
							task,
							"One or more Tasks have invalid dependencies." ) );
					
					return;
				}
			}
			
			checkForCompletionOrRunAllReadyTasks();
		}
		
		/*
		* Helper methods
		*/
		
		private function areAllInnerTasksCompleted():Boolean {
			for each ( var task:ITask in _tasks ) {
				if ( !task.isComplete ) {
					return false;
				}
			}
			
			return true;
		}
		
		private function atLeastOneInnerTaskIsActive():Boolean {
			for each ( var task:ITask in _tasks ) {
				if ( task.isRunning ) {
					return true;
				}
			}
			
			return false;
		}
		
		private function checkForCompletionOrRunAllReadyTasks():void {
			if ( areAllInnerTasksCompleted() ) {
				taskComplete();
			} else if ( _erroredTasks.length == 0 ) {
				runAllReadyTasks();
			} else if ( !atLeastOneInnerTaskIsActive() ) {
				taskError( errorMessages.join( "\n" ), errorDatas );
			}
		}
		
		private function doesTaskHaveInvalidDependencies( currentTask:ITask, dependencies:Array ):Boolean {
			if ( _taskIDToDependenciesMap[ currentTask.id ] is Array ) {
				for each ( var blockingTask:ITask in _taskIDToDependenciesMap[ currentTask.id ] ) {
					
					// If current Task is dependent upon another Task that is not in the queue...
					if ( _tasks.getItemIndex( blockingTask ) < 0 ) {
						return true;
					}
					
					// If current Task depends on another Task that has already been depended on higher in the chain...
					if ( dependencies.indexOf( blockingTask ) >= 0 ) {
						return true;
					}
					
					var clonedDependencies:Array = dependencies.concat();
					clonedDependencies.push( blockingTask );
					
					if ( doesTaskHaveInvalidDependencies( blockingTask, clonedDependencies ) ) {
						return true;
					}
				}
			}
			
			return false;
		}
		
		private function markTaskComplete( task:ITask ):void {
		}
		
		private function runAllReadyTasks():void {
			for each ( var task:ITask in _tasks ) {
				if ( !taskDependenciesAreSatisfied( task ) ) continue;
				
				// TRICKY: If a Task synchronously completes it will lead to another, simultaneous invocation of this method.
				// If this 2nd invocation starts a subsequent Task that synchronously errors,
				// We run the risk of re-executing that failed Task when we return to this method.
				// To avoid this, we must check to make sure that the Task we are examining has not already errored on this run of the Task Manager.
				// We cannot rely on task.isErrored because it may have errored on a previous run of the Task Manager.
				// In that case it would be okay to re-run it.
				if ( _erroredTasks.indexOf( task ) >= 0 ) continue;
				
				if ( !task.isComplete ) {
					task.addEventListener( TaskEvent.COMPLETE, onTaskComplete );
					task.addEventListener( TaskEvent.ERROR, onTaskError );
					task.addEventListener( ProgressEvent.PROGRESS, onTaskProgress );
					
					task.run();
				}
			}
		}
		
		private function taskDependenciesAreSatisfied( task:ITask ):Boolean {
			if ( _taskIDToDependenciesMap[ task.id ] is Array ) {
				for each ( var blockingTask:ITask in _taskIDToDependenciesMap[ task.id ] ) {
					if ( !blockingTask.isComplete ) {
						return false;
					}
					if ( !taskDependenciesAreSatisfied( blockingTask ) ) {
						return false;
					}
				}
			}
			
			return true;
		}
		
		/*
		* Event listeners
		*/
		
		private function onTaskComplete( event:TaskEvent ):void {
			var task:ITask = event.currentTarget as ITask;
			task.removeEventListener( TaskEvent.COMPLETE, onTaskComplete );
			task.removeEventListener( TaskEvent.ERROR, onTaskError );
			task.removeEventListener( ProgressEvent.PROGRESS, onTaskProgress );
			
			markTaskComplete( task );
			
			checkForCompletionOrRunAllReadyTasks();
		}
		
		private function onTaskError( event:TaskEvent ):void {
			var task:ITask = event.currentTarget as ITask;
			
			_erroredTasks.push( task );
			
			checkForCompletionOrRunAllReadyTasks();
		}
		
		private function onTaskProgress( event:ProgressEvent ):void {
			dispatchProgressEvent();
		}
		
		private function onTaskManagerComplete( event:TaskEvent ):void { 
			dispatchEvent( new TaskManagerEvent( TaskManagerEvent.COMPLETE ) ); 
		}
		
		private function onTaskManagerError( event:TaskEvent ):void { 
			dispatchEvent( new TaskManagerEvent( TaskManagerEvent.ERROR, event.data as ITask, event.message ) );
		}
	}
}