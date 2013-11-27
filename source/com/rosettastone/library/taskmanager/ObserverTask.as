package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.events.TaskEvent;
	
	import flash.events.ProgressEvent;
	
	use namespace TaskPrivateNamespace;
	
	/**
	 * Observes (but does not execute) a collection of Tasks.
	 * This task can be used to monitor the execution of 1 or more running Tasks.
	 * Tasks can be added (or removed) while the observer is running.
	 * It will complete only once all observed Tasks has completed.
	 * 
	 * If any of the observed Tasks errors, the observer will error as well if failUponError is TRUE. 
	 * In this case the observer will re-dispatch the "data" and "message" properties of the first Task to fail. 
	 * If failUponError is FALSE, observed Task errors and complets will be treated the same.
	 * 
	 * If this Task is executed with no observed Tasks it will instantly complete.
	 * The same is true if all of its observed Tasks have already completed by the time it has been executed.
	 */
	public class ObserverTask extends Task {
		
		protected var _failUponError:Boolean;
		protected var _observedTasks:Array;
		
		/**
		 * Constructor.
		 * 
		 * @param tasks Array of Tasks to observe
		 * @param failUponError Controls behavior in the event of a Task error; see class documentation for more detail
		 * @param taskIdentifier
		 */
		public function ObserverTask( tasks:Array = null,
		                              failUponError:Boolean = true,
		                              taskIdentifier:String = null ) {
			
			super( taskIdentifier );
			
			_failUponError = failUponError;
			
			_observedTasks = new Array();
			
			for each ( var taskToObserve:ITask in tasks ) {
				if ( _observedTasks.indexOf( taskToObserve ) < 0 ) {
					_observedTasks.push( taskToObserve );
				}
			}
		}
		
		/**
		 * Array of Tasks currently observed by this Task.
		 */
		TaskPrivateNamespace function get observedTasks():Array {
			return _observedTasks;
		}
		
		/**
		 * Add an additional Task to the set of Tasks being observed.
		 */
		public function observeTask( taskToObserve:ITask ):void {
			if ( _observedTasks.indexOf( taskToObserve ) < 0 ) {
				_observedTasks.push( taskToObserve );
			}
			
			taskToObserve.addEventListener( TaskEvent.COMPLETE, onTaskComplete );
			taskToObserve.addEventListener( TaskEvent.ERROR, onTaskError );
			taskToObserve.removeEventListener( ProgressEvent.PROGRESS, onIndividualTaskProgress );
		}
		
		/**
		 * Remove the specified Task from the set of Tasks being observed.
		 */
		public function stopObservingTask( taskToObserve:ITask ):void {
			if ( _observedTasks.indexOf( taskToObserve ) >= 0 ) {
				_observedTasks.splice(
					_observedTasks.indexOf( taskToObserve ), 1 );
			}
			
			taskToObserve.removeEventListener( TaskEvent.COMPLETE, onTaskComplete );
			taskToObserve.removeEventListener( TaskEvent.ERROR, onTaskError );
			taskToObserve.removeEventListener( ProgressEvent.PROGRESS, onIndividualTaskProgress );
			
			checkForAndHandleCompletion();
		}
		
		/*
		 * Task overrides
		 */
		
		/**
		 * @inheritDoc
		 */
		override public function get numInternalOperations():int {
			var returnValue:int = 0;
			
			for each ( var task:ITask in _observedTasks ) {
				returnValue += task.numInternalOperations;
			}
			
			return returnValue;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get numInternalOperationsCompleted():int {
			var returnValue:int = 0;
			
			for each ( var task:ITask in _observedTasks ) {
				returnValue += task.numInternalOperationsCompleted;
			}
			
			return returnValue;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customRun():void {
			if ( areAllObservedTasksCompletedOrErrored() ) {
				taskComplete();
				
			} else {
				for each ( var task:ITask in _observedTasks ) {
					task.addEventListener( TaskEvent.COMPLETE, onTaskComplete );
					task.addEventListener( TaskEvent.ERROR, onTaskError );
					task.addEventListener( ProgressEvent.PROGRESS, onIndividualTaskProgress );
				}
			}
		}
		
		/*
		 * Helper methods
		 */
		
		protected function areAllObservedTasksCompletedOrErrored():Boolean {
			var returnValue:Boolean = true;
			
			for each ( var task:ITask in _observedTasks ) {
				if ( !task.isComplete && !task.isErrored ) {
					returnValue = false;
					
					break;
				}
			}
			
			return returnValue;
		}
		
		protected function checkForAndHandleCompletion():void {
			if ( areAllObservedTasksCompletedOrErrored() ) {
				taskComplete();
			}
		}
		
		/*
		 * Event handlers
		 */
		
		private function onIndividualTaskProgress( event:ProgressEvent ):void {
			dispatchProgressEvent();
		}
		
		private function onTaskComplete( event:TaskEvent ):void {
			event.currentTarget.removeEventListener( TaskEvent.COMPLETE, onTaskComplete );
			event.currentTarget.removeEventListener( TaskEvent.ERROR, onTaskError );
			event.currentTarget.removeEventListener( ProgressEvent.PROGRESS, onIndividualTaskProgress );
			
			checkForAndHandleCompletion();
		}
		
		private function onTaskError( event:TaskEvent ):void {
			event.currentTarget.removeEventListener( TaskEvent.COMPLETE, onTaskComplete );
			event.currentTarget.removeEventListener( TaskEvent.ERROR, onTaskError );
			event.currentTarget.removeEventListener( ProgressEvent.PROGRESS, onIndividualTaskProgress );
			
			if ( _failUponError ) {
				taskError( event.message, event.data );
			} else {
				checkForAndHandleCompletion();
			}
		}
	}
}