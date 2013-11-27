package com.rosettastone.library.taskmanager {
	
	public class CompositeTaskContainingThreeStubTasks extends CompositeTask {
		
		private var _stubTask1:StubTask;
		private var _stubTask2:StubTask;
		private var _stubTask3:StubTask;
		
		public function CompositeTaskContainingThreeStubTasks( executeTaskInParallel:Boolean = true ) {
			super( null, executeTaskInParallel );
			
			_stubTask1 = new StubTask( true );
			_stubTask2 = new StubTask( true );
			_stubTask3 = new StubTask( true );
		}
		
		public function get stubTask1():StubTask {
			return _stubTask1;
		}
		
		public function get stubTask2():StubTask {
			return _stubTask2;
		}
		
		public function get stubTask3():StubTask {
			return _stubTask3;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function addTasksBeforeRun():void {
			addTask( _stubTask1 );
			addTask( _stubTask2 );
			addTask( _stubTask3 );
		}
	}
}