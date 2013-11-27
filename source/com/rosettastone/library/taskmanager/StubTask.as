package com.rosettastone.library.taskmanager {

	/**
	 * Empty Task useful primarily for unit testing.
	 * It can also be useful in factory situations when a default no-op behavior is desired.
	 * If certain implementations wish to provide behavior they can replace the placeholder Stub task with one that does work.
	 * 
	 * This Task can be configured to auto-complete when it is executed.
	 * Otherwise it will not complete or error unless/until specifically told to do so.
	 */
	public class StubTask extends Task {

		private var _autoCompleteUponRun:Boolean;
		
		/**
		 * Constructor.
		 * 
		 * @param autoCompleteUponRun If TRUE Task will synchronously complete when it is run
		 * @param taskIdentifier Semantically meaningful task identifier (useful for automated testing or debugging)
		 */
		public function StubTask( autoCompleteUponRun:Boolean = false,
		                          taskIdentifier:String = null ) {
			
			super( taskIdentifier );
			
			_autoCompleteUponRun = autoCompleteUponRun;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get synchronous():Boolean {
			return _autoCompleteUponRun;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customRun():void {
			if ( _autoCompleteUponRun ) {
				complete();
			}
		}
		
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