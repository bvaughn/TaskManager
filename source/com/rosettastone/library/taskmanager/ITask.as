package com.rosettastone.library.taskmanager {
	import flash.events.IEventDispatcher;
	
	[Event( name="taskEventComplete", type="com.rosettastone.library.taskmanager.events.TaskEvent" )]
	[Event( name="taskEventError", type="com.rosettastone.library.taskmanager.events.TaskEvent" )]
	[Event( name="taskEventFinal", type="com.rosettastone.library.taskmanager.events.TaskEvent" )]
	[Event( name="taskEventStarted", type="com.rosettastone.library.taskmanager.events.TaskEvent" )]
	[Event( name="progress", type="flash.events.ProgressEvent" )]
	
	/**
	 * A Task represents a job.
	 * This job can be synchronous or asynchronous.
	 * It can be a simple operation or a composite of other Tasks.
	 * This interface defines the minimum API that must be implemented by a Task within the Task Manager framework.
	 */
	public interface ITask extends IEventDispatcher {
		
		/**
		 * Optional data parameter passed to the Task complete/error/interruption method.
		 */
		function get data():*;
		
		/**
		 * The current task has successfully completed execution.
		 */
		function get isComplete():Boolean;
		
		/**
		 * The current task failed.
		 */
		function get isErrored():Boolean;
		
		/**
		 * The task is currently running.
		 * This value is FALSE if the task has not been run, has completed run (succesfully or due to a failure), or has been interrupted.
		 */
		function get isRunning():Boolean;
		
		/**
		 * @private
		 * This accessor is being left in place to support backwards compatibility.
		 */
		function get id():Number;
		
		/**
		 * Optional message parameter passed to the task complete/error/interruption method.
		 */
		function get message():String;
		
		/**
		 * Number of internal operations conducted by this task.
		 * Sub-classes should override this method if containing a value > 1;
		 * 
		 * If value > 1, task should dispatch ProgressEvent.PROGRESS events manually to indicate changes in numInternalOperationsCompleted.
		 * If value == 1, task will automatically dispatching ProgressEvent.PROGRESS events.
		 */
		function get numInternalOperations():int;
		
		/**
		 * Number of internal operations that have completed.
		 * Sub-classes should override this method if containing a value > 1;
		 */
		function get numInternalOperationsCompleted():int;
		
		/**
		 * Number of internal operations not yet completed.
		 */
		function get numInternalOperationsPending():int;
		
		/**
		 * Number of times this task has completed.
		 */
		function get numTimesCompleted():int;
		
		/**
		 * Number of times this task has errored.
		 */
		function get numTimesErrored():int;
		
		/**
		 * Number of times this task has been interrupted.
		 */
		function get numTimesInterrupted():int;
		
		/**
		 * Number of times this task has been reset.
		 * This is the only counter that is not reset by the reset() method.
		 */
		function get numTimesReset():int;
		
		/**
		 * Number of times this task has been started.
		 */
		function get numTimesStarted():int;
		
		/**
		 * Resets the task to it's pre-run state.
		 * This allows it to be re-run.
		 * This method can only be called on non-running tasks.
		 */
		function reset():void;
		
		/**
		 * Starts a task.
		 * This method will dispatch a TaskEvent.STARTED to indicate that the task has begun.
		 * 
		 * This method may also be used to retry/resume an errored task.
		 */
		function run():ITask;
		
		/**
		 * The task is currently running.
		 * This value is FALSE if the task has not been run, has completed run (succesfully or due to a failure), or has been interrupted.
		 */
		function get running():Boolean;
		
		/**
		 * The current task can be executed synchronously.
		 */
		function get synchronous():Boolean;
		
		/**
		 * (Optional) human-readable label for task.
		 */
		function get taskIdentifier():String;
		function set taskIdentifier( value:String ):void;
		
		/**
		 * Unique ID for a task.
		 */
		function get uniqueID():Number
		
		/*
		 * Chaining methods
		 */
		
		/**
		 * Executes the specified tasks when the current task is executed.
		 * If the current task has already been started the new tasks will be executed immediately.
		 * Failures or interruptions in the current task will not affect the chained tasks.
		 * 
		 * @includeExample TaskAndExample.as
		 * 
		 * @param chainedTasks One or more tasks
		 * 
		 * @throws Error if any parameter is not a task
		 */
		function and( ...chainedTasks ):ITask;
		
		/**
		 * Executes the specified tasks if the current task fails.
		 * 
		 * @includeExample TaskOrExample.as
		 * 
		 * @param chainedTasks One or more tasks
		 * 
		 * @throws Error if any parameter is not a task
		 */
		function or( ...chainedTasks ):ITask;
		
		/**
		 * Executes the specified tasks once the current task has completed successfully.
		 * 
		 * @includeExample TaskThenExample.as
		 * 
		 * @param chainedTasks One or more tasks
		 * 
		 * @throws Error if any parameter is not a task
		 */
		function then( ...chainedTasks ):ITask;
		
		/*
		 * Event handler alternatives
		 */
		
		/**
		 * Although tasks dispatch TaskEvents to indicate completion, this method may also be used for notification purposes.
		 * The provided function will be invoked only upon successful completion of the task.
		 * 
		 * This method may be called multiple times safely; each unique function specified will be executed once when the task completes.
		 * 
		 * <p>
		 * It should have one of the following signatures:
		 * <pre>function( message:String = "", data:* = null ):void</pre>
		 * <pre>function():void</pre>
		 * </p>
		 *
		 * @param completeHandler Function
		 */
		function withCompleteHandler( completeHandler:Function ):ITask;
		
		/**
		 * Although tasks dispatch TaskEvents to indicate failure, this method may also be used for notification purposes.
		 * The provided function will be invoked only upon failure of the task.
		 * 
		 * This method may be called multiple times safely; each unique function specified will be executed once if the tasks errors.
		 * 
		 * <p>
		 * It should have one of the following signatures:
		 * <pre>function( message:String = "", data:* = null ):void</pre>
		 * <pre>function():void</pre>
		 * </p>
		 *
		 * @param errorHandler Function
		 */
		function withErrorHandler( errorHandler:Function ):ITask;
		
		/**
		 * This handler is invoked upon either success or failure of the Task.
		 * It can be used for cleanup that must be done regardless of Task-status.
		 * 
		 * <p>
		 * This method may be called multiple times safely.
		 * Each unique function specified will be executed once when the task is ready for cleanup.
		 * </p>
		 * 
		 * <p>
		 * This type of closure should implement the following signature:
		 * <pre>function():void</pre>
		 * </p>
		 */
		function withFinalHandler( finalHandler:Function ):ITask;
		
		/**
		 * Although tasks dispatch TaskEvents to indicate starting, this method may also be used for notification purposes.
		 * The provided function will be invoked each time the task is started (or re-started).
		 * 
		 * This method may be called multiple times safely; each unique function specified will be executed once when the task starts.
		 * 
		 * <p>
		 * It should have the following signature:
		 * <pre>function():void</pre>
		 * </p>
		 *
		 * @param startedHandler Function
		 */
		function withStartedHandler( startedHandler:Function ):ITask;
	}
}