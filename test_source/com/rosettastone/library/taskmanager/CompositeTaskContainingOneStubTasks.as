package com.rosettastone.library.taskmanager {
	
	public class CompositeTaskContainingOneStubTasks extends CompositeTask {
		
		private var _stubTask1:StubTask;
		
		public function CompositeTaskContainingOneStubTasks( executeTaskInParallel:Boolean = true ) {
			super( null, executeTaskInParallel );
			
			_stubTask1 = new StubTask( true );
		}
		
		public function get stubTask1():StubTask {
			return _stubTask1;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function addTasksBeforeRun():void {
			addTask( _stubTask1 );
		}
	}
}