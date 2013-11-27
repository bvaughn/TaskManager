package com.rosettastone.library.taskmanager {
	
	/**
	 * Special interface for tasks that decorate other tasks.
	 * This interface can assist external code in getting to the lowest-level failing task in the event of an error.
	 */
	public interface IDecoratorTask extends ITask {
		
		/**
		 * Inner (decorated) Task.
		 */
		function get decoratedTask():ITask;
	}
}