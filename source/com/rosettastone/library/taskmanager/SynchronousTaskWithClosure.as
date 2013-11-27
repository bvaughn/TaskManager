package com.rosettastone.library.taskmanager {
	
	public class SynchronousTaskWithClosure extends TaskWithClosure implements ISynchronousTask, IInterruptibleTask {
		
		public function SynchronousTaskWithClosure( customRunFunction:Function = null,
		                                            taskIdentifier:String = null ) {
			
			super( customRunFunction, true, taskIdentifier );
		}
	}
}