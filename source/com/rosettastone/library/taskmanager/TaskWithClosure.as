package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.Task;
	
	/**
	 * Task that invokes a specified function upon execution.
	 * The function invoked will retain the scope of where it was defined, allowing for easy access to other class/method variables.
	 * 
	 * This type of Task can be asynchronous.
	 * It will not complete (or error) until specifically instructed to do so.
	 * This instruction should be triggered as a result of the custom function it executes.
	 */
	public class TaskWithClosure extends Task {

		private var _autoCompleteAfterRunningFunction:Boolean;
		private var _customRunFunction:Function;

		/**
		 * Constructor.
		 * 
		 * @param customRunFunction Function to be executed when this Task is run
		 * @param autoCompleteAfterRunningFunction If TRUE this Task will complete after running custom function (unless custom function called "errorTask")
		 * @param taskIdentifier Semantically meaningful task identifier (useful for automated testing or debugging)
		 */
		public function TaskWithClosure( customRunFunction:Function = null,
		                                 autoCompleteAfterRunningFunction:Boolean = false,
		                                 taskIdentifier:String = null ) {
			
			super( taskIdentifier );
			
			this.autoCompleteAfterRunningFunction = autoCompleteAfterRunningFunction;
			this.customRunFunction = customRunFunction;
		}
		
		/**
		 * If TRUE this Task will synchronously complete itself once it has invoked its custom run function.
		 * If an error occurs during the functions execution however the Task will not dispatch a redundant complete event.
		 */
		public function get autoCompleteAfterRunningFunction():Boolean {
			return _autoCompleteAfterRunningFunction;
		}
		public function set autoCompleteAfterRunningFunction( value:Boolean ):void {
			_autoCompleteAfterRunningFunction = value;
		}
		
		/**
		 * Function to be executed when this Task is run
		 */
		public function get customRunFunction():Function {
			return _customRunFunction;
		}
		public function set customRunFunction( value:Function ):void {
			_customRunFunction = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function get synchronous():Boolean {
			return autoCompleteAfterRunningFunction;
		}

		/**
		 * @inheritDoc
		 */
		override protected function customRun():void {
			try {
				_customRunFunction();
				
				if ( running && autoCompleteAfterRunningFunction ) {
					taskComplete();
				}
				
			} catch ( error:Error ) {
				taskError( error.message );
			}
		}
		
		/**
		 * Instructs Task to complete itself.
		 */
		public function finishTask( message:String = "", data:* = null ):void {
			taskComplete( message, data );
		}
		
		/**
		 * Instructs Task to dispatch an error event.
		 */
		public function errorTask( message:String = "", data:* = null ):void {
			taskError( message, data );
		}
	}
}