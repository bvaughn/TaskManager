package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.events.TaskEvent;
	import com.rosettastone.library.taskmanager.events.TaskManagerEvent;
	
	import flash.events.ProgressEvent;
	
	import mx.collections.ArrayCollection;
	
	[Event( name="taskManagerEventComplete", type="com.rosettastone.library.taskmanager.events.TaskManagerEvent" )]
	[Event( name="taskManagerEventError", type="com.rosettastone.library.taskmanager.events.TaskManagerEvent" )]
	[Event( name="taskManagerEventInterrupted", type="com.rosettastone.library.taskmanager.events.TaskManagerEvent" )]
	
	/**
	 * Manages execution of a set of ITasks.
	 * Tasks may specify blocking depencies on other tasks.
	 *
	 * This class will wrap all TaskEvents and dispatch TaskManagerEvent.COMPLETE only once all Tasks have completed.
	 * If a task errors, this class will dispatch a TaskManagerEvent.ERROR event and halt running any additional tasks.
	 */
	public class TaskManager extends AbstractTaskManager {
		
		/**
		 * Constructor.
		 * 
		 * @param interruptible Consider using InterruptibleTaskManager instead of this parameter.
		 */
		public function TaskManager( interruptible:Boolean = false ) {
			super( interruptible );
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
		public function addTask( task:ITask, dependencies:Array = null ):void {
			super.addTaskHelper( task, dependencies );
		}
		
		/**
		 * Removes a task from the task manager.
		 * 
		 * If the TaskManager is running and this operation unblocks any of the remaining Tasks, they will be executed as a result of this removal.
		 *
		 * @param taskToRemove The task to remove
		 */
		public function removeTask( taskToRemove:ITask ):void {
			super.removeTaskHelper( taskToRemove );
		}
	}
}