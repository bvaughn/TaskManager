package unittests {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	/** 
	 * By default this contains everything necessary for a TestSuite to succeed in the automated
	 * unit test driver. For special cases such as CustomTextField, override the 'bootstrapUnitTestSuite'
	 * method with bootstrapping functionality then dispatch the 'READY_TO_EXECUTE_UNIT_TEST' event
	 */
	public class TestSuiteBase extends EventDispatcher {
		/** Event to notify the automated unit test driver that this TestSuite is ready to be executed */
		public static const READY_TO_EXECUTE_UNIT_TEST:String = "READY_TO_EXECUTE_UNIT_TEST";
		
		/** Override this in the base TestSuite class if any bootstrapping is necessary */
		public function bootstrapUnitTestSuite(unitTestView:Object=null):void {
			dispatchEvent(new Event(READY_TO_EXECUTE_UNIT_TEST));
		}
	}
}