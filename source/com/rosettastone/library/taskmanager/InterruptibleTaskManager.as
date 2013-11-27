package com.rosettastone.library.taskmanager {
	
	/**
	 * Manages execution of a set of IInterruptibleTasks.
	 * Tasks may specify blocking depencies on other tasks.
	 *
	 * This class will wrap all TaskEvents and dispatch TaskManagerEvent.COMPLETE only once all Tasks have completed.
	 * If a task errors, this class will dispatch a TaskManagerEvent.ERROR event and halt running any additional tasks.
	 */
	public class InterruptibleTaskManager extends AbstractTaskManager implements IInterruptibleTask {
		
		/**
		 * Constructor.
		 */
		public function InterruptibleTaskManager() {
			super( true );
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
		public function addTask( task:IInterruptibleTask, dependencies:Array = null ):void {
			super.addTaskHelper( task, dependencies );
		}
		
		/**
		 * Removes a task from the task manager.
		 * 
		 * If the TaskManager is running and this operation unblocks any of the remaining Tasks, they will be executed as a result of this removal.
		 *
		 * @param taskToRemove The task to remove
		 */
		public function removeTask( taskToRemove:IInterruptibleTask ):void {
			super.removeTaskHelper( taskToRemove );
		}
	}
}