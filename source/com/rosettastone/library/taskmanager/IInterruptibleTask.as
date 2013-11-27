package com.rosettastone.library.taskmanager {
	
	[Event( name="taskEventInterrupted", type="com.rosettastone.library.taskmanager.events.TaskEvent" )]
	
	/**
	 * An interruptible Task can be paused and resumed after being run.
	 * 
	 * Pausing a non-running Task should have no effect.
	 * Resuming a non-interrupted Task should have no effect.
	 */
	public interface IInterruptibleTask extends ITask {
		
		/**
		 * If an interrupting-Task has been provided (via interruptForTask) this Task will automatically resume when it completes.
		 * This method to cancels that behavior by removing references and event listeners.
		 */
		function disconnectFromInterruptingTask():void;
		
		/**
		 * The task has been interrupted and has not yet resumed.
		 */
		function get isInterrupted():Boolean;
		
		/**
		 * Interrupt the current Task.
		 * Interruptions should be handled in such a way as to allow a subsequent call to run() to resume gracefully.
		 * 
		 * This mehtod should trigger an event of type TaskEvent.INTERRUPTED.
		 * 
		 * @return TRUE if the Task has been successfully interrupted
		 */
		function interrupt():Boolean;
		
		/**
		 * The Task currently interrupting the this Task's execution (or NULL if no such Task exists).
		 */
		function get interruptingTask():ITask;
		
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
		 * 
		 * @return TRUE if the Task has been successfully interrupted
		 */
		function interruptForTask( interruptingTask:ITask ):Boolean;
		
		/**
		 * Although Tasks dispatch TaskEvents to indicate interruption this method may also be used for notification purposes.
		 * The provided function will be invoked only upon interruption of the Task.
		 * 
		 * This method may be called multiple times safely; each unique function specified will be executed once if the task interrupts.
		 * 
		 * <p>
		 * It should have one of the following signatures:
		 * <pre>function( message:String = "", data:* = null ):void</pre>
		 * <pre>function():void</pre>
		 * </p>
		 * 
		 * @param interruptionHandler Function
		 */
		function withInterruptionHandler( interruptionHandler:Function ):ITask;
	}
}