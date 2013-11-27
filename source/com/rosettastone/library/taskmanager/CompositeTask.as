package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.events.TaskEvent;
	
	import flash.events.ProgressEvent;
	import flash.utils.Dictionary;
	
	use namespace TaskPrivateNamespace;
	
	/**
	 * Wraps a set of ITasks and executes them in parallel or serial, as specified by a boolean constructor arg.
	 */
	public class CompositeTask extends AbstractCompositeTask {
		
		/**
		 * Constructor
		 * 
		 * @param tasksOrFunctions Set of Tasks and/or functions to be executed
		 * @param executeTaskInParallel When TRUE, execute all tasks and report if all succeed (COMPLETE) or not (ERROR)
		 *                              When FALSE, execute tasks in order.  Do not execute subsequent tasks if one fails.
		 * @para taskIdentifier Human friendly identifier for Task
		 * 
		 * @throws Error if tasksOrFunctions Array contains object that is not a Task or a Function
		 */
		public function CompositeTask( tasksOrFunctions:Array = null,
		                               executeTaskInParallel:Boolean = true,
		                               taskIdentifier:String = null ) {
			
			super( tasksOrFunctions, executeTaskInParallel, taskIdentifier );
		}
		
		/**
		 * Adds another task to the internal set that this class will execute.
		 * Additional tasks may be safely at any time (including while the CompositeTask is executing).
		 * Tasks are added to the end, so in serial tasks, tasks added later will not be run if an earlier one fails.
		 */
		public function addTask( task:ITask ):void {
			addTaskHelper( task );
		}
	}
}