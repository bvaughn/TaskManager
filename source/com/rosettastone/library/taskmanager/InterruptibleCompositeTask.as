package com.rosettastone.library.taskmanager {
	
	/**
	 * Wraps a set of IInterruptibleTask (or ISynchronousTask) and executes them in parallel or serial, as specified by a boolean constructor arg.
	 * Interruptable composite task designed to be paused and resumed gracefully and automatically handles interrupting and resuming all child tasks.
	 * 
	 * @throws Error if given a non-interruptable, non-synchronous child Task
	 */
	public class InterruptibleCompositeTask extends AbstractCompositeTask implements IInterruptibleTask {
		
		/**
		 * Constructor
		 * 
		 * @param tasksOrFunctions Set of Tasks and/or functions to be executed
		 * @param executeTaskInParallel When TRUE, execute all tasks and report if all succeed (COMPLETE) or not (ERROR)
		 *                              When FALSE, execute tasks in order.  Do not execute subsequent tasks if one fails.
		 * @para taskIdentifier Human friendly identifier for Task
		 * 
		 * @throws Error if tasksOrFunctions Array contains object that is not either an IInterruptibleTask, ISynchronousTask, or a Function
		 */
		public function InterruptibleCompositeTask( tasksOrFunctions:Array = null,
		                                            executeTaskInParallel:Boolean = true,
		                                            taskIdentifier:String = null ) {
			
			super( null, executeTaskInParallel, taskIdentifier );
			
			for each ( var taskOrFunction:* in tasksOrFunctions ) {
				if ( taskOrFunction is IInterruptibleTask ) {
					addTask( taskOrFunction as IInterruptibleTask );
				} else if ( taskOrFunction is ISynchronousTask ) {
					addSynchronousTask( taskOrFunction as ISynchronousTask );
				} else if ( taskOrFunction is Function ) {
					addFunction( taskOrFunction as Function );
				} else {
					throw Error( "Array must contain only IInterruptibleTask, ISynchronousTask, or Function type objects" );
				}
			}
		}
		
		/**
		 * Adds another task to the internal set that this class will execute.
		 * Additional tasks may be safely at any time (including while the CompositeTask is executing).
		 * Tasks are added to the end, so in serial tasks, tasks added later will not be run if an earlier one fails.
		 */
		public function addTask( task:IInterruptibleTask ):void {
			super.addTaskHelper( task );
		}
		
		/**
		 * Adds another task to the internal set that this class will execute.
		 * Additional tasks may be safely at any time (including while the CompositeTask is executing).
		 * Tasks are added to the end, so in serial tasks, tasks added later will not be run if an earlier one fails.
		 */
		public function addSynchronousTask( task:ISynchronousTask ):void {
			super.addTaskHelper( task );
		}
	}
}