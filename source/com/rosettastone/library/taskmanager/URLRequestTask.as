package com.rosettastone.library.taskmanager {
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	/**
	 * Task that loads a URLRequest and exposes the URLLoader's "urlLoaderData" upon success.
	 */
	public class URLRequestTask extends InterruptibleTask {
		
		private var _urlLoader:URLLoader;
		private var _urlRequest:URLRequest;
		
		/**
		 * Constructor.
		 * 
		 * @param urlRequest
		 */
		public function URLRequestTask( urlRequest:URLRequest, taskIdentifier:String = null ) {
			super( taskIdentifier );
			
			_urlRequest = urlRequest;
		}
		
		/**
		 * Loaded data.
		 * This should only be accessed after the Task has completed.
		 */
		public function get urlLoaderData():* {
			return _urlLoader ? _urlLoader.data : null;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customInterrupt():void {
			if ( _urlLoader ) {
				removeListeners();
				
				try {
					_urlLoader.close();
					_urlLoader = null;
					
				} catch ( error:Error ) {
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function customRun():void {
			_urlLoader = new URLLoader();
			_urlLoader.addEventListener( Event.COMPLETE, onComplete, false, 0, true );
			_urlLoader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onSecurityError, false, 0, true );
			_urlLoader.addEventListener( IOErrorEvent.IO_ERROR, onIOError, false, 0, true );
			_urlLoader.addEventListener( IOErrorEvent.NETWORK_ERROR, onIOError, false, 0, true );
			_urlLoader.addEventListener( IOErrorEvent.VERIFY_ERROR, onIOError, false, 0, true );
			_urlLoader.addEventListener( IOErrorEvent.DISK_ERROR, onIOError, false, 0, true );
			
			// Have to add this event (even though we don't use it) or AIR will return a Stream Error #2032
			// Won't be defined though if we're running in a web context so we have to check for that case also
			if ( HTTPStatusEvent.HTTP_RESPONSE_STATUS ) {
				_urlLoader.addEventListener( HTTPStatusEvent.HTTP_RESPONSE_STATUS, onStatus );
			}
			
			_urlLoader.load( _urlRequest );
		}
		
		/*
		* Event handlers
		*/
		
		private function removeListeners():void {
			_urlLoader.removeEventListener(Event.COMPLETE, onComplete, false);
			_urlLoader.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, onSecurityError, false );
			_urlLoader.removeEventListener( IOErrorEvent.IO_ERROR, onIOError, false );
			_urlLoader.removeEventListener( IOErrorEvent.NETWORK_ERROR, onIOError, false );
			_urlLoader.removeEventListener( IOErrorEvent.VERIFY_ERROR, onIOError, false );
			_urlLoader.removeEventListener( IOErrorEvent.DISK_ERROR, onIOError, false );
			
			if ( HTTPStatusEvent.HTTP_RESPONSE_STATUS ) {
				_urlLoader.removeEventListener( HTTPStatusEvent.HTTP_RESPONSE_STATUS, onStatus );
			}
		}
		
		private function onComplete( event:Event ):void {
			removeListeners();
			
			taskComplete( "", urlLoaderData );
		}
		
		private function onIOError( event:IOErrorEvent ):void {
			removeListeners();
			
			taskError( event.text );
		}
		
		private function onSecurityError( event:SecurityErrorEvent ):void {
			removeListeners();
			
			taskError( event.text );
		}
		
		private function onStatus( event:HTTPStatusEvent ):void {
			// No-op
		}
	}
}