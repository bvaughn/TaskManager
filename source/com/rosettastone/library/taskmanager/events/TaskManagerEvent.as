package com.rosettastone.library.taskmanager.events {
	import com.rosettastone.library.taskmanager.ITask;
	
	import flash.events.Event;
	
	/**
	 * Dispatched by TaskManager to indicate a change in state.
	 */
	public class TaskManagerEvent extends Event {
		
		public static const COMPLETE:String = "taskManagerEventComplete";
		public static const INTERRUPTED:String = "taskManagerEventInterrupted";
		public static const ERROR:String = "taskManagerEventError";
		
		private var _message:String;
		private var _task:ITask;
		
		/**
		 * @param type Event type
		 * @param task Errored task (if event type is ERROR)
		 * @param message Optional message
		 */
		public function TaskManagerEvent( type:String, task:ITask = null, message:String = null ) {
			super( type );
			
			_message = message;
			_task = task;
		}
		
		/**
		 * Optional human-readable message.
		 */
		public function get message():String {
			return _message;
		}
		
		/**
		 * Task associated with error (in the event of an error).
		 */
		public function get task():ITask {
			return _task;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function clone():Event {
			return new TaskManagerEvent( type, task, message );
		}
	}
}