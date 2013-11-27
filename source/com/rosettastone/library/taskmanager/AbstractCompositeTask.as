package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.events.TaskEvent;
	
	import flash.events.ProgressEvent;
	import flash.utils.Dictionary;
	
	/**
	 * This is an abstract class and should not be instantiated directly.
	 * Instead use one of the following sub-classes: CompositeTask, InterruptibleCompositeTask
	 */
	public class AbstractCompositeTask extends Task {
		
		protected var _addTasksBeforeRunInvoked:Boolean;
		protected var _erroredTasks:Array;
		protected var _executeTaskInParallel:Boolean;
		protected var _flushTaskQueueLock:Boolean;
		protected var _interruptedTask:ITask;
		protected var _taskQueue:Array;
		protected var _taskQueueIndex:int; // Only used for serial execution
		
		/**
		 * @private
		 */
		public function AbstractCompositeTask( tasksOrFunctions:Array = null,
		                                       executeTaskInParallel:Boolean = true,
		                                       taskIdentifier:String = null ) {
			
			super( taskIdentifier );
			
			_executeTaskInParallel = executeTaskInParallel;
			_taskQueue = new Array();
			_taskQueueIndex = 0;
			
			addMultiple.apply( this, tasksOrFunctions );
		}
		
		TaskPrivateNamespace function get taskQueue():Array {
			return _taskQueue;
		}
		
		TaskPrivateNamespace function get taskQueueIndex():int {
			return _taskQueueIndex;
		}
		
		/*
		* Public methods
		*/
		
		/**
		 * Adds a function to the queue of Tasks by wrapping it inside of a TaskWithClosure.
		 * Functions added this way must be synchronous.
		 * This method is simply a convenience method for creating a TaskWithClosure and calling addTask().
		 * 
		 * @param closure Function to be executed
		 * @param closureIdentifier Unique identifier for function (and its TaskWithClosure)
		 * 
		 * @return Newly created TaskWithClosure
		 */
		public function addFunction( closure:Function, closureIdentifier:String = null ):TaskWithClosure {
			var taskWithClosure:TaskWithClosure =
				new TaskWithClosure(
					closure,
					true,
					closureIdentifier );
			
			addTaskHelper( taskWithClosure );
			
			return taskWithClosure;
		}
		
		/**
		 * Adds multiple Tasks or Functions to the internal set.
		 * This method is a convenience mehtod for calling addTask() or addFunction() multiple times.
		 * 
		 * @param tasksOrFunctions Task or Function objects
		 * 
		 * @throws Error if any of the specified parameters is not a Task or a Function
		 */
		public function addMultiple( ...tasksOrFunctions ):void {
			for each ( var taskOrFunction:Object in tasksOrFunctions ) {
				if ( taskOrFunction is Task ) {
					addTaskHelper( taskOrFunction as ITask );
				} else if ( taskOrFunction is Function ) {
					addFunction( taskOrFunction as Function );
				} else {
					throw Error( "Only Task or Function arguments allowed" );
				}
			}
		}
		
		/**
		 * Adds another task to the internal set that this class will execute.
		 * Additional tasks may be safely at any time (including while the CompositeTask is executing).
		 * Tasks are added to the end, so in serial tasks, tasks added later will not be run if an earlier one fails.
		 */
		protected function addTaskHelper( task:ITask ):void {
			_taskQueue.push( task );
			
			// Don't invoke Tasks if we're still in the addTasksBeforeRun() method.
			// Synchronous Task failures at this point can cause problems.
			if ( running && _addTasksBeforeRunInvoked ) {
				addTaskEventListeners( task );
				
				if ( _executeTaskInParallel ) {
					task.run();
				} else if ( currentSerialTask == task ) {
					task.run();
				}
			}
		}
		
		/**
		 * Removes a function from the queue of Tasks by locating its corresponding TaskWithClosure.
		 * This method is simply a convenience method for locating the matching Task and calling removeTask().
		 * 
		 * @param closure Function to be executed
		 * 
		 * @return TaskWithClosure (if one found)
		 */
		public function removeFunction( closure:Function ):TaskWithClosure {
			for each ( var task:ITask in _taskQueue ) {
				if ( task is TaskWithClosure &&
					( task as TaskWithClosure ).customRunFunction == closure ) {
					
					removeTask( task );
					
					return task as TaskWithClosure;
				}
			}
			
			return null;
		}
		
		/**
		 * Removes multiple Tasks or Functions from the internal set.
		 * This method is a convenience mehtod for calling removeTask() or removeFunction() multiple times.
		 * 
		 * @param tasksOrFunctions Task or Function objects
		 * 
		 * @throws Error if any of the specified parameters is not a Task or a Function
		 */
		public function removeMultiple( ...tasksOrFunctions ):void {
			for each ( var taskOrFunction:Object in tasksOrFunctions ) {
				if ( taskOrFunction is Task ) {
					removeTask( taskOrFunction as ITask );
				} else if ( taskOrFunction is Function ) {
					removeFunction( taskOrFunction as Function );
				} else {
					throw Error( "Only Task or Function arguments allowed" );
				}
			}
		}
		
		/**
		 * Removes a task from the internal set that this class will execute.
		 * If the specified Task has not been executed before it is removed it will not be executed by the CompositeTask.
		 */
		public function removeTask( task:ITask ):void {
			removeTaskEventListeners( task );
			
			var indexOfTask:int = _taskQueue.indexOf( task );
			
			if ( indexOfTask < 0 ) return;
			
			_taskQueue.splice( indexOfTask, 1 );
			
			if ( running ) {
				if ( _executeTaskInParallel || indexOfTask <= _taskQueueIndex ) {
					_taskQueueIndex--;
				}
				
				if ( task.running || ( task is IInterruptibleTask && ( task as IInterruptibleTask ).isInterrupted ) ) {
					handleTaskCompletedOrRemoved( task );
				}
			}
		}
		
		/*
		* Accessors
		*/
		
		/**
		 * No incomplete Tasks remain in the queue.
		 */
		protected function get allTasksAreCompleted():Boolean {
			for each ( var task:ITask in _taskQueue ) {
				if ( !task.isComplete ) {
					return false;
				}
			}
			
			return true;
		}
		
		/**
		 * References the Task that is currently running (if this CompositeTask has been told to execute in serial).
		 */
		protected function get currentSerialTask():ITask {
			return _taskQueue && _taskQueue.length > _taskQueueIndex ? _taskQueue[ _taskQueueIndex ] as ITask : null;
		}
		
		/**
		 * Unique error messages from all inner Tasks that failed during execution.
		 * This value is valid after during execution of the CompositeTask as well as upon completion (or failure).
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
		 * This value is valid after during execution of the CompositeTask as well as upon completion (or failure).
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
		 * This value is valid after during execution of the CompositeTask as well as upon completion (or failure).
		 */
		public function get erroredTasks():Array {
			return _erroredTasks;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get interruptible():Boolean {
			for each ( var task:ITask in _taskQueue ) {
				if ( !( task is IInterruptibleTask ) && !task.synchronous ) {
					return false;
				}
			}
			
			return true;
		}
		
		/**
		 * Number of inner Tasks that have successfully completed.
		 * This value is only valid while the CompositeTask is running.
		 * Upon completion (or failure) of the CompositeTask this value will be reset to 0.
		 */
		public function get numCompletedTasks():int {
			return numTasks - numPendingTasks;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get numInternalOperations():int {
			var returnValue:int = 0;
			
			for each ( var task:ITask in _taskQueue ) {
				returnValue += task.numInternalOperations;
			}
			
			return returnValue;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get numInternalOperationsCompleted():int {
			var returnValue:int = 0;
			
			for each ( var task:ITask in _taskQueue ) {
				returnValue += task.numInternalOperationsCompleted;
			}
			
			return returnValue;
		}
		
		/**
		 * Number of inner Tasks that have been started and have not yet completed.
		 * This value is only valid while the CompositeTask is running (or before it has been started).
		 * Upon completion (or failure) of the CompositeTask this value will be reset to 0.
		 */
		public function get numPendingTasks():int {
			return pendingTasks.length;
		}
		
		/**
		 * Number of inner Tasks.
		 * This value is only valid while the CompositeTask is running (or before it has been started).
		 * Upon completion (or failure) of the CompositeTask this value will be reset to 0.
		 */
		public function get numTasks():int {
			return _taskQueue.length;
		}
		
		/**
		 * Tasks currently in the process of being executed.
		 * This value is only valid while the CompositeTask is running (or before it has been started).
		 * Upon completion (or failure) of the CompositeTask this value will be reset to 0.
		 */
		public function get pendingTasks():Array {
			return _taskQueue.slice( _taskQueueIndex );
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get synchronous():Boolean {
			for each ( var task:ITask in _taskQueue ) {
				if ( !task.synchronous ) {
					return false;
				}
			}
			
			return true;
		}
		
		/*
		* Helper methods
		*/
		
		/**
		 * Remove all Tasks from the queue.
		 * 
		 * @param forcefullyPreventTaskFromCompleting Prevent CompositeTask from completing after queue has been cleared
		 */
		protected function flushTaskQueue( forcefullyPreventTaskFromCompleting:Boolean = false ):void {
			
			// If instructed to keep the CompositeTask running, set this lock.
			// See checkForTaskComplete() for more information.
			_flushTaskQueueLock = forcefullyPreventTaskFromCompleting;
			
			// Manually interrupt any Task that may be running
			if ( currentSerialTask is IInterruptibleTask ) {
				( currentSerialTask as IInterruptibleTask ).interrupt();
			}
			
			// Remove Tasks in reverse order to prevent accidentially triggering the next Task
			while ( _taskQueue.length > 0 ) {
				var task:ITask = _taskQueue[ _taskQueue.length - 1 ] as ITask;
				
				removeTask( task );
			}
			
			// Manually reset the Task-index since we are doing a non-standard thing here by preventing CompositeTask from completing as we remove.
			_taskQueueIndex = 0;
			
			_flushTaskQueueLock = false;
		}
		
		/*
		* Subclass hooks
		*/
		
		/**
		 * Sub-classes may override this method to J.I.T. add child Tasks before the composite Task is run.
		 */
		protected function addTasksBeforeRun():void {
		}
		
		/**
		 * Override this method to be notified when individual Tasks have successfully completed.
		 */
		protected function individualTaskComplete( task:ITask ):void {
		}
		
		/**
		 * Override this method to be notified when individual Tasks are started.
		 */
		protected function individualTaskStarted( task:ITask ):void {
		}
		
		/*
		* Override methods
		*/
		
		/**
		 * @inheritDoc
		 */
		override public function interrupt():Boolean {
			if ( !running ) return false;
			if ( !interruptible ) return false;
			
			taskInterrupted(); // Updates interrupted state and dispatches events
			
			if ( !_executeTaskInParallel ) {
				if ( currentSerialTask is IInterruptibleTask ) {
					( currentSerialTask as IInterruptibleTask ).interrupt();
				}
				
			} else {
				for each ( var task:ITask in _taskQueue ) {
					if ( task.running ) {
						if ( task is IInterruptibleTask ) {
							( task as IInterruptibleTask ).interrupt();
						}
					}
				}
			}
			
			return true;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customReset():void {
			if ( _taskQueue.length > 0 ) {
				for ( var index:int = 0; index <= _taskQueueIndex; index++ ) {
					var task:ITask = _taskQueue[ index ] as ITask;
					task.reset();
				}
			}
			
			_taskQueueIndex = 0;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customRun():void {
			if ( !_addTasksBeforeRunInvoked ) {
				addTasksBeforeRun();
				
				_addTasksBeforeRunInvoked = true;
			}
			
			if ( _taskQueue.length == 0 || allTasksAreCompleted ) {
				taskComplete();
				
				return;
			}
			
			_erroredTasks = new Array();
			
			var task:ITask;
			
			for each ( task in _taskQueue ) {
				addTaskEventListeners( task );
			}
			
			if ( _executeTaskInParallel ) {
				for each ( task in _taskQueue ) {
					task.run();
				}
				
			} else {
				currentSerialTask.run();
			}
		}
		
		/*
		* Helper methods
		*/
		
		/**
		 * Convenience method for adding TaskEvent listeners to a Task.
		 */
		protected function addTaskEventListeners( task:ITask ):void {
			// Listen with a low priority to ensure that external event handlers get executed first.
			// This avoids the odd use-case where a Task-complete handler is executed after CompositeTask has already started the next Task.
			task.addEventListener( TaskEvent.COMPLETE, onIndividualTaskComplete, false, -1 );
			task.addEventListener( TaskEvent.ERROR, onIndividualTaskError, false, -1 );
			task.addEventListener( TaskEvent.STARTED, onIndividualTaskStarted, false, -1 );
			task.addEventListener( ProgressEvent.PROGRESS, onIndividualTaskProgress, false, -1 );
		}
		
		protected function checkForTaskCompletion():void {
			
			// This lock will only be set to true if the flushTaskQueue() method is operating.
			// In this case, we don't want to allow the composite to complete itself.
			if ( _flushTaskQueueLock ) return;
			
			// If the composite is running in parallel, it will wait until all inner-Tasks have completed (or errored) to notify of an error.
			// This method needs to take the number of failed tasks into consideration in addition to the number of successful/completed Tasks.
			if ( _taskQueue.length >= _taskQueueIndex + 1 + _erroredTasks.length ) {
				return;
			}
			
			if ( _erroredTasks && _erroredTasks.length > 0 ) {
				taskError( errorMessages.join( "\n" ), errorDatas );
				
			} else {
				taskComplete();
			}
		}
		
		/**
		 * Convenience method for handling a completed Task and executing the next.
		 */
		protected function handleTaskCompletedOrRemoved( task:ITask ):void {
			removeTaskEventListeners( task );
			
			// If this Task was removed before completion, don't call the Task-complete hook.
			if ( task.isComplete ) {
				individualTaskComplete( task );
			}
			
			_taskQueueIndex++;
			
			// Handle edge-case where an inner Task's complete handler resulted in the composite's interruption 
			if ( !running ) return;
			
			if ( _executeTaskInParallel ) {
				checkForTaskCompletion();
				
			} else {
				if ( currentSerialTask ) {
					currentSerialTask.run();
				} else {
					checkForTaskCompletion();
				}
			}
		}
		
		/**
		 * Convenience method for removing TaskEvent listeners from a Task.
		 */
		protected function removeTaskEventListeners( task:ITask ):void {
			task.removeEventListener( TaskEvent.COMPLETE, onIndividualTaskComplete );
			task.removeEventListener( TaskEvent.ERROR, onIndividualTaskError );
			task.removeEventListener( TaskEvent.STARTED, onIndividualTaskStarted );
			task.removeEventListener( ProgressEvent.PROGRESS, onIndividualTaskProgress );
		}
		
		/*
		* Event handlers
		*/
		
		private function onIndividualTaskComplete( event:TaskEvent ):void {
			var task:ITask = event.currentTarget as ITask;
			
			handleTaskCompletedOrRemoved( task );
		}
		
		private function onIndividualTaskError( event:TaskEvent ):void {
			var task:ITask = event.currentTarget as ITask;
			
			removeTaskEventListeners( task );
			
			_erroredTasks.push( task );
			
			// Don't halt execution in parallel mode
			if ( _executeTaskInParallel ) {
				checkForTaskCompletion();
			} else {
				taskError( event.message, event.data );
			}
		}
		
		private function onIndividualTaskStarted( event:TaskEvent ):void {
			var task:ITask = event.currentTarget as ITask;
			
			individualTaskStarted( task );
		}
		
		private function onIndividualTaskProgress( event:ProgressEvent ):void {
			dispatchProgressEvent();
		}
	}
}