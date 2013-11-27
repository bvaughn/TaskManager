package com.rosettastone.library.taskmanager {
	
	/**
	 * Useful for automated tests only.
	 * This Task can help make automated tests a little less verbose.
	 */
	public class SynchronousStubTask extends SynchronousTaskWithClosure {
		
		private var _completeSuccessfully:Boolean;
		
		public function SynchronousStubTask( completeSuccessfully:Boolean = true, taskIdentifier:String = null ) {
			super( runFunction, taskIdentifier );
			
			_completeSuccessfully = completeSuccessfully;
		}
		
		private function runFunction():void {
			if ( _completeSuccessfully ) {
				taskComplete();
			} else {
				taskError();
			}
		}
	}
}