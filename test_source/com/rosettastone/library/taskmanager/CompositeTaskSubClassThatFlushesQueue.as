package com.rosettastone.library.taskmanager {
	
	public class CompositeTaskSubClassThatFlushesQueue extends CompositeTask {
		
		public var phaseOne_stubTask_1:InterruptibleStubTask;
		public var phaseOne_stubTask_2:InterruptibleStubTask;
		public var phaseOne_stubTask_3:InterruptibleStubTask;
		public var phaseOne_numTasks:int = 3;
		
		public var phaseTwo_stubTask_1:InterruptibleStubTask;
		public var phaseTwo_stubTask_2:InterruptibleStubTask;
		public var phaseTwo_numTasks:int = 2;
		
		public function CompositeTaskSubClassThatFlushesQueue( executeTaskInParallel:Boolean ) {
			super( null, executeTaskInParallel );
		}
		
		public function setupQueuePhaseOne():void {
			phaseOne_stubTask_1 = new InterruptibleStubTask();
			phaseOne_stubTask_2 = new InterruptibleStubTask();
			phaseOne_stubTask_3 = new InterruptibleStubTask();
			
			addMultiple( phaseOne_stubTask_1, phaseOne_stubTask_2, phaseOne_stubTask_3 );
		}
		
		public function setupQueuePhaseTwo():void {
			flushTaskQueue( true );
			
			phaseTwo_stubTask_1 = new InterruptibleStubTask();
			phaseTwo_stubTask_2 = new InterruptibleStubTask();
			
			addMultiple( phaseTwo_stubTask_1, phaseTwo_stubTask_2 );
		}
		
		public function doFlushTaskQueue( forcefullyPreventTaskFromCompleting:Boolean ):void {
			flushTaskQueue( forcefullyPreventTaskFromCompleting );
		}
	}
}