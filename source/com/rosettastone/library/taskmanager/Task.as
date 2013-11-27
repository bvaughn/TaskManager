package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.events.TaskEvent;
	
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	use namespace TaskPrivateNamespace;
	
	[Event( name="taskEventComplete", type="com.rosettastone.library.taskmanager.events.TaskEvent" )]
	[Event( name="taskEventError", type="com.rosettastone.library.taskmanager.events.TaskEvent" )]
	[Event( name="taskEventFinal", type="com.rosettastone.library.taskmanager.events.TaskEvent" )]
	[Event( name="taskEventStarted", type="com.rosettastone.library.taskmanager.events.TaskEvent" )]
	[Event( name="taskEventInterrupted", type="com.rosettastone.library.taskmanager.events.TaskEvent" )]
	[Event( name="progress", type="flash.events.ProgressEvent" )]
	
	/**
	 * This class is meant to encapsulate a single, self-contained job.
	 * Each instance can have 0+ dependencies in the form of other tasks.
	 * 
	 * To create a usable Task, extend this class and override the customRun() method.
	 * Your Task should call taskComplete() or taskError() when it has completed or failed.
	 */
	public class Task extends EventDispatcher implements ITask {
		
		TaskPrivateNamespace static var ID:Number = 0;
		
		TaskPrivateNamespace var _complete:Boolean = false;
		TaskPrivateNamespace var _completeHandlers:Array;
		TaskPrivateNamespace var _data:*;
		TaskPrivateNamespace var _errored:Boolean;
		TaskPrivateNamespace var _errorHandlers:Array;
		TaskPrivateNamespace var _finalHandlers:Array;
		TaskPrivateNamespace var _interrupted:Boolean;
		TaskPrivateNamespace var _interruptingTask:ITask;
		TaskPrivateNamespace var _interruptionHandlers:Array;
		TaskPrivateNamespace var _logger:ILogger;
		TaskPrivateNamespace var _message:String = "";
		TaskPrivateNamespace var _numTimesCompleted:int;
		TaskPrivateNamespace var _numTimesErrored:int;
		TaskPrivateNamespace var _numTimesInterrupted:int;
		TaskPrivateNamespace var _numTimesReset:int;
		TaskPrivateNamespace var _numTimesStarted:int;
		TaskPrivateNamespace var _running:Boolean = false;
		TaskPrivateNamespace var _startedHandlers:Array;
		TaskPrivateNamespace var _taskHasBeenRunAtLeastOnce:Boolean;
		TaskPrivateNamespace var _taskIdentifier:String;
		TaskPrivateNamespace var _uniqueID:Number;
		
		/**
		 * Constructor
		 * 
		 * @param taskIdentifier Human-friendly ID string useful for debugging purposes only.
		 */
		public function Task( taskIdentifier:String = null ) {
			_taskIdentifier = taskIdentifier;
			_uniqueID = ID++;
			
			_completeHandlers = new Array();
			_errorHandlers = new Array();
			_finalHandlers = new Array();
			_interruptionHandlers = new Array();
			_startedHandlers = new Array();
			
			var className:String = getQualifiedClassName( this ).replace( "::", "." ).replace( "$", "." ); // $ may appear inside of private classes used by unit tests
			
			_logger = Log.getLogger( className );
			
			_numTimesCompleted = _numTimesErrored = _numTimesInterrupted = _numTimesReset = _numTimesStarted = 0;
		}
		
		/*
		 * Accessor methods
		 */
		
		/**
		 * @inheritDoc
		 */
		public function get data():* {
			return _data;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get isComplete():Boolean {
			return _complete;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get isErrored():Boolean {
			return _errored;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get isRunning():Boolean {
			return _running;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get isInterrupted():Boolean {
			return _interrupted;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get id():Number {
			return uniqueID;
		}
		
		/**
		 * Instance of ILogger to be used for any custom Task logging.
		 */
		protected function get logger():ILogger {
			return _logger;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get message():String {
			return _message;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get numInternalOperations():int {
			return 1;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get numInternalOperationsCompleted():int {
			return isComplete ? 1 : 0;
		}
		
		/**
		 * @inheritDoc
		 */
		public final function get numInternalOperationsPending():int {
			return numInternalOperations - numInternalOperationsCompleted;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get numTimesCompleted():int {
			return _numTimesCompleted;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get numTimesErrored():int {
			return _numTimesErrored;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get numTimesInterrupted():int {
			return _numTimesInterrupted;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get numTimesReset():int {
			return _numTimesReset;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get numTimesStarted():int {
			return _numTimesStarted;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get running():Boolean {
			return _running;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get taskIdentifier():String {
			return _taskIdentifier;
		}
		public function set taskIdentifier( value:String ):void {
			_taskIdentifier = value;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get uniqueID():Number {
			return _uniqueID;
		}
		
		/**
		 * @inheritDoc
		 */
		public function disconnectFromInterruptingTask():void {
			if ( _interruptingTask ) {
				_interruptingTask.removeEventListener( TaskEvent.COMPLETE, onInterruptingTaskComplete );
				_interruptingTask.removeEventListener( TaskEvent.ERROR, onInterruptingTaskError );
				_interruptingTask = null;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function reset():void {
			if ( running ) return;
			if ( numTimesStarted == 0 ) return;
			
			_numTimesReset++;
			
			_complete = false;
			_errored = false;
			_interrupted = false;
			
			_numTimesCompleted = _numTimesErrored = _numTimesInterrupted = _numTimesStarted = 0;
			
			customReset();
		}
		
		/**
		 * @inheritDoc
		 */
		public final function run():ITask {
			if ( running ) return this;
			
			logger.debug( getLoggerString( "Task started" ) );
			
			_taskHasBeenRunAtLeastOnce = true;
			
			disconnectFromInterruptingTask();
			
			if ( !_complete ) {
				_interrupted = false;
				_running = true;
				
				_numTimesStarted++;
				
				for each ( var startedHandler:Function in _startedHandlers ) {
					startedHandler();
				}
				
				dispatchEvent( new TaskEvent( TaskEvent.STARTED ) );
				
				customRun();
			}
			
			return this;
		}
		
		/**
		 * Interruptible tasks should override interrupt() and get interruptible() if they are interruptible.
		 * 
		 * If they are, they should fire a TaskEvent.INTERRUPTED to indicate successful interruption of the task.
		 * 
		 * If the interrupting fails at runtime, this method returns false
		 */
		public function interrupt():Boolean {
			return false;
		}
		
		/**
		 * The Task currently interrupting the composite Task's execution (or NULL if no such Task exists).
		 */
		public function get interruptingTask():ITask {
			return _interruptingTask;
		}
		
		/**
		 * Interrupts the current Task to wait on the Task specified.
		 * Once this Task dispatches a TaskEvent.COMPLETE event, this Task will resume.
		 * If the specified Task dispatches a TaskEvent.ERROR event this Task will also error.
		 * TaskEvent.INTERRUPTED events are ignored.
		 * 
		 * If this method is called once with a Task and then called again before that Task has completed,
		 * Event listeners will be removed from the first Task and added to the second one.
		 * There can only be 1 active interrupting Task at a time.
		 * If this Task should be interrupted by more than one Task, a CompositeTask or ObserverTask should be used.
		 * 
		 * If the specified interrupting Task is already running this method will simply add event listeners.
		 * If it is not running this method will add event listeners but will rely on external code to run the interrupter.
		 * 
		 * @param interruptingTask Task
		 */
		public function interruptForTask( interruptingTask:ITask ):Boolean {
			if ( !interruptible ) return false;
			
			if ( running ) {
				var returnValue:Boolean = interrupt();
			}
			
			if ( _interruptingTask ) {
				_interruptingTask.removeEventListener( TaskEvent.COMPLETE, onInterruptingTaskComplete );
				_interruptingTask.removeEventListener( TaskEvent.ERROR, onInterruptingTaskError );
			}
			
			if ( !isComplete && !isErrored ) {
				_interruptingTask = interruptingTask;
				_interruptingTask.addEventListener( TaskEvent.COMPLETE, onInterruptingTaskComplete );
				_interruptingTask.addEventListener( TaskEvent.ERROR, onInterruptingTaskError );
			}
			
			return returnValue;
		}
		
		/**
		 * The current Task can be interrupted.
		 * Invoking interrupt() for a Task that is not marked as interruptible may result in an error.
		 */
		public function get interruptible():Boolean {
			return false;
		}
		
		/**
		 * @inheritDoc
		 */
		public function get synchronous():Boolean {
			return false;
		}
		
		/*
		 * Override methods
		 */
		
		/**
		 * Override this method to perform any custom reset operations.
		 */
		protected function customReset():void {
		}
		
		/**
		 * Override this method to give your Task functionality.
		 */
		protected function customRun():void {
			throw new Error( "customRun method must be implemented" );
		}
		
		/*
		 * Helper methods
		 */
		
		protected function dispatchProgressEvent():void {
			dispatchEvent(
				new ProgressEvent(
					ProgressEvent.PROGRESS,
					false,
					false,
					numInternalOperationsCompleted,
					numInternalOperations ) );
		}
		
		/**
		 * Returns a string for logging the specified task-state event.
		 * 
		 * @param string String to append to log
		 */
		protected function getLoggerString( string:String ):String {
			var loggerID:String = "id: " + id;
			
			if ( taskIdentifier ) {
				loggerID += ", taskIdentifier: \"" + taskIdentifier + "\"";
			}
			
			return string + " [" + loggerID + "] at " + getTimer() + " ms";
		}
		
		/**
		 * This method should be called upon Task completion.
		 * It dispatches a TaskEvent.COMPLETE event and toggles the Tasks's "running" and "complete" states.
		 * It also invokes the success handler if one has been provided.
		 * 
		 * @param message An (optional) message or data in string form
		 * @param data Optional data object related to the Task dispatching this event.
		 */
		protected function taskComplete( message:String = "", data:* = null ):void {
			if ( !_running ) return;
			
			logger.debug( getLoggerString( "Task completed" ) );
			
			_data = data;
			_message = message;
			
			_numTimesCompleted++;
			
			_complete = true;
			_interrupted = false;
			_running = false;
			
			// Auto-dispatch ProgressEvents for the simple case.
			if ( numInternalOperations == 1 ) {
				dispatchProgressEvent();
			}
			
			for each ( var completeHandler:Function in _completeHandlers ) {
				try {
					completeHandler( message, data );
				} catch ( error:Error ) {
					completeHandler();
				}
			}
			
			dispatchEvent( new TaskEvent( TaskEvent.COMPLETE, message, data ) );
			
			for each ( var finalHandler:Function in _finalHandlers ) {
				finalHandler();
			}
			
			dispatchEvent( new TaskEvent( TaskEvent.FINAL ) );
		}
		
		/**
		 * This method should be called upon Task failure.
		 * It dispatches a TaskEvent.ERROR event and toggles the Tasks's "running" and "complete" states.
		 * It also invokes the error handler if one has been provided.
		 * 
		 * @param message An (optional) reason for the error
		 * @param data Optional data object containing additional error information
		 */
		protected function taskError( message:String = "", data:* = null ):void {
			if ( !_running ) return;
			
			logger.error( getLoggerString( "Task errored" ) );
			
			_data = data;
			_message = message;
			
			_numTimesErrored++;
			
			_errored = true;
			
			_interrupted = false;
			_running = false;
			
			for each ( var errorHandler:Function in _errorHandlers ) {
				try {
					errorHandler( message, data );
				} catch ( error:Error ) {
					errorHandler();
				}
			}
			
			dispatchEvent( new TaskEvent( TaskEvent.ERROR, message, data ) );
			
			for each ( var finalHandler:Function in _finalHandlers ) {
				finalHandler();
			}
			
			dispatchEvent( new TaskEvent( TaskEvent.FINAL ) );
		}
		
		/**
		 * Call this method to interrupt the currently running Task.
		 * This method dispatches a TaskEvent.INTERRUPTED and toggles the tasks's "running" state.
		 * 
		 * @param message An (optional) reason for the interruption
		 */
		protected function taskInterrupted( message:String = "", data:* = null ):void {
			if ( !_running ) return;
			
			logger.debug( getLoggerString( "Task interrupted" ) );
			
			_data = data;
			_message = message;
			
			_numTimesInterrupted++;
			
			_interrupted = true;
			_running = false;
			
			for each ( var interruptionHandler:Function in _interruptionHandlers ) {
				try {
					interruptionHandler( message, data );
				} catch ( error:Error ) {
					interruptionHandler();
				}
			}
			
			dispatchEvent( new TaskEvent( TaskEvent.INTERRUPTED, message ) );
		}
		
		protected function throwErrorIfAnyObjectInArrayIsNotATask( tasks:Array ):void {
			for each ( var expectedTask:Object in tasks ) {
				if ( !( expectedTask is Task ) ) {
					throw Error( "Parameter of type " + expectedTask + " provided when type Task was expected" );
				}
			}
		}
		
		/*
		 * Chaining methods
		 */
		
		/**
		 * @inheritDoc
		 */
		public function and( ...chainedTasks ):ITask {
			throwErrorIfAnyObjectInArrayIsNotATask( chainedTasks );
			
			if ( running || isComplete ) {
				for each ( var chainedTask:ITask in chainedTasks ) {
					chainedTask.run();
				}
				
			} else {
				addEventListener(
					TaskEvent.STARTED,
					function( event:TaskEvent ):void {
						removeEventListener( TaskEvent.STARTED, arguments.callee );
						
						for each ( var chainedTask:ITask in chainedTasks ) {
							chainedTask.run();
						}
					} );
			}
			
			return this;
		}
		
		/**
		 * @inheritDoc
		 */
		public function or( ...chainedTasks ):ITask {
			throwErrorIfAnyObjectInArrayIsNotATask( chainedTasks );
			
			addEventListener(
				TaskEvent.ERROR,
				function( event:TaskEvent ):void {
					removeEventListener( TaskEvent.ERROR, arguments.callee );
					
					for each ( var chainedTask:ITask in chainedTasks ) {
						chainedTask.run();
					}
				} );
			
			return this;
		}
		
		/**
		 * @inheritDoc
		 */
		public function then( ...chainedTasks ):ITask {
			throwErrorIfAnyObjectInArrayIsNotATask( chainedTasks );
			
			addEventListener(
				TaskEvent.COMPLETE,
				function( event:TaskEvent ):void {
					removeEventListener( TaskEvent.COMPLETE, arguments.callee );
					
					for each ( var chainedTask:ITask in chainedTasks ) {
						chainedTask.run();
					}
				} );
			
			return this;
		}
		
		/*
		 * Convenience methods
		 */
		
		/**
		 * @inheritDoc
		 */
		public function withCompleteHandler( completeHandler:Function ):ITask {
			if ( _completeHandlers.indexOf( completeHandler ) < 0 ) {
				_completeHandlers.push( completeHandler );
			}
			
			return this;
		}
		
		/**
		 * @inheritDoc
		 */
		public function withErrorHandler( errorHandler:Function ):ITask {
			if ( _errorHandlers.indexOf( errorHandler ) < 0 ) {
				_errorHandlers.push( errorHandler );
			}
			
			return this;
		}
		
		/**
		 * @inheritDoc
		 */
		public function withFinalHandler( finalHandler:Function ):ITask {
			if ( _finalHandlers.indexOf( finalHandler ) < 0 ) {
				_finalHandlers.push( finalHandler );
			}
			
			return this;
		}
		
		/**
		 * @inheritDoc
		 */
		public function withInterruptionHandler( interruptionHandler:Function ):ITask {
			if ( _interruptionHandlers.indexOf( interruptionHandler ) < 0 ) {
				_interruptionHandlers.push( interruptionHandler );
			}
			
			return this;
		}
		
		/**
		 * @inheritDoc
		 */
		public function withStartedHandler( startedHandler:Function ):ITask {
			if ( _startedHandlers.indexOf( startedHandler ) < 0 ) {
				_startedHandlers.push( startedHandler );
			}
			
			return this;
		}
		
		/*
		 * Event handlers
		 */
		
		TaskPrivateNamespace function onInterruptingTaskComplete( event:TaskEvent ):void {
			_interruptingTask.removeEventListener( TaskEvent.COMPLETE, onInterruptingTaskComplete );
			_interruptingTask.removeEventListener( TaskEvent.ERROR, onInterruptingTaskError );
			_interruptingTask = null;
			
			if ( _taskHasBeenRunAtLeastOnce ) {
				run();
			}
		}
		
		TaskPrivateNamespace function onInterruptingTaskError( event:TaskEvent ):void {
			_interruptingTask.removeEventListener( TaskEvent.COMPLETE, onInterruptingTaskComplete );
			_interruptingTask.removeEventListener( TaskEvent.ERROR, onInterruptingTaskError );
			_interruptingTask = null;
			
			if ( _taskHasBeenRunAtLeastOnce ) {
				// TRICKY: Task won't dispatch an ERROR event unless it's running.
				// This is normally a good thing, but in our case- we want to error despite the fact that we've been interrupted.
				// The only wayt o accomplish this is to resume the Task and then immediately error.
				_running = true;
				
				taskError( event.message, event.data );
			}
		}
		
		/*
		 * Unit test helper methods
		 */
		
		TaskPrivateNamespace function doTaskComplete( message:String = "", data:* = null ):void {
			taskComplete( message, data );
		}
		
		TaskPrivateNamespace function doTaskError( message:String = "", data:* = null ):void {
			taskError( message, data );
		}
		
		TaskPrivateNamespace function doTaskInterrupted( message:String = "", data:* = null ):void {
			taskInterrupted( message, data );
		}
	 }
}