package com.rosettastone.library.taskmanager.events {
	import flash.events.Event;
	
	/**
	 * Dispatched by a Task to indicated a change in state.
	 */
	public class TaskEvent extends Event {

		public static const COMPLETE:String = "taskEventComplete";
		public static const ERROR:String = "taskEventError";
		public static const FINAL:String = "taskEventFinal";
		public static const STARTED:String = "taskEventStarted";
		public static const INTERRUPTED:String = "taskEventInterrupted";

		private var _data:*;
		private var _message:String;

		public function TaskEvent( type:String, message:String = "", data:* = null ) {
			super( type );

			_data = data;
			_message = message;
		}
		
		/**
		 * Optional data object related to the Task dispatching this event.
		 * If the event is an error event this object may also contain more information about the error.
		 */
		public function get data():* {
			return _data;
		}
		public function set data( value:* ):void {
			_data = value;
		}
		
		/**
		 * Optional human-readable message.
		 */
		public function get message():String {
			return _message;
		}
		public function set message( value:String ):void {
			_message = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Event {
			return new TaskEvent( type, message, data );
		}
	}
}