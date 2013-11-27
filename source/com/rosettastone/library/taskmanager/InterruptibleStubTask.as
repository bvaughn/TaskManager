package com.rosettastone.library.taskmanager {
	
	/**
	 * Interruptible stub Task primarily intended for use in the context of automated tests.
	 * This Task does nothing when run (nor when interrupted) other than increment the Task counter.
	 * It can be manually completed or errored at any point using the <code>complete</code> and <code>error</code> methods.
	 */
	public class InterruptibleStubTask extends InterruptibleTask {
		
		private var _autoCompleteUponRun:Boolean;
		
		public function InterruptibleStubTask( autoCompleteUponRun:Boolean = false,
		                                       taskIdentifier:String = null ) {
			
			_autoCompleteUponRun = autoCompleteUponRun;
		}
		
		/*
		 * Task overrides
		 */
		
		/**
		 * @inheritDoc
		 */
		override protected function customRun():void {
			if ( _autoCompleteUponRun ) {
				taskComplete();
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customInterrupt():void {
			// No-op
		}
		
		/*
		 * Convenience methods
		 */
		
		/**
		 * Instructs Task to complete itself.
		 */
		public function complete( message:String = "", data:* = null ):void {
			taskComplete( message, data );
		}
		
		/**
		 * Instructs Task to dispatch an error event.
		 */
		public function error( message:String = "", data:* = null ):void {
			taskError( message, data );
		}
	}
}