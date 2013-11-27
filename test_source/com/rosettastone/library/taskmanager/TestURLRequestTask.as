package com.rosettastone.library.taskmanager {
	import com.rosettastone.library.taskmanager.events.TaskEvent;
	
	import flash.net.URLRequest;
	import flexunit.framework.BetterTestCase;
	
	
	public class TestURLRequestTask extends BetterTestCase {
		
		private var _urlRequestTask:URLRequestTask;
		
		[Test]
		public function test_loadInvalidPath():void {
			_urlRequestTask = new URLRequestTask( new URLRequest( "fake" ) );
			_urlRequestTask.addEventListener(
				TaskEvent.ERROR,
				addAsync(
					function( event:TaskEvent ):void {
						// No-op
					}, 1000 ) );
			_urlRequestTask.run();
		}
		
		[Test]
		public function test_loadXML():void {
			_urlRequestTask = new URLRequestTask( new URLRequest( "assets/test.xml" ) );
			_urlRequestTask.addEventListener(
				TaskEvent.COMPLETE,
				addAsync(
					function( event:TaskEvent ):void {
						assertNotNull( _urlRequestTask.data );
						
						var xml:XML = new XML( _urlRequestTask.data );
						
						assertEquals( "baz", xml.bar.toString() );
						assertEquals( _urlRequestTask.urlLoaderData, _urlRequestTask.data );
					}, 1000 ) );
				_urlRequestTask.run();
		}
	}
}
