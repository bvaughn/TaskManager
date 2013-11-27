package com.rosettastone.library.taskmanager {
	
	public class CompositeTaskSubClass extends CompositeTask {
		
		private var _individualTasksCompleted:Array;
		
		public function CompositeTaskSubClass( tasks:Array = null, executeTaskInParallel:Boolean = true ) {
			super( tasks, executeTaskInParallel );
			
			_individualTasksCompleted = new Array();
		}
		
		public function get individualTasksCompleted():Array {
			return _individualTasksCompleted;
		}
		
		override protected function individualTaskComplete( task:ITask ):void {
			individualTasksCompleted.push( task );
		}
	}
}