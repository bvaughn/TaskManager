package flexunit.framework  {
	
	/**
	 * Flex Unit's assert methods are bullshit.
	 * They accept an Array of parameters but only look at 1 or 2 of them (depending on the assertion).
	 * In order to prevent your tests from being unnecessarily verbose, extend this class and use its assert methods instead.
	 * Just in case it isn't clear, fuck Flex Unit.
	 */
	public class BetterTestCase extends TestCase {
		
		public function BetterTestCase( methodName:String=null ) {
			super( methodName );
		}
		
		protected function assertEquals( ...rest ):void {
			if ( rest.length < 2 ) fail( "Expected a minimum of 2 parameters to compare" );
			
			var firstValue:* = rest[0];
			
			for each ( var value:* in rest ) {
				if ( value != firstValue ) {
					fail( 'Expected "' + firstValue + '" but was "' + value + '"' );
				}
			}
		}
		
		protected function assertFalse( ...rest ):void {
			for each ( var value:* in rest ) {
				if ( Boolean( value ) ) {
					fail( "Expected FALSE but was TRUE" );
				}
			}
		}
		
		protected function assertNotNull( ...rest ):void {
			for each ( var value:* in rest ) {
				if ( value == null ) {
					fail( "Expected not-NULL but was NULL" );
				}
			}
		}
		
		protected function assertNull( ...rest ):void {
			for each ( var value:* in rest ) {
				if ( value != null ) {
					fail( 'Expected NULL but was "' + value + '"' );
				}
			}
		}
		
		protected function assertStrictlyEquals( ...rest ):void {
			if ( rest.length < 2 ) fail( "Expected a minimum of 2 parameters to compare" );
			
			var firstValue:* = rest[0];
			
			for each ( var value:* in rest ) {
				if ( value !== firstValue ) {
					fail( 'Expected "' + firstValue + '" but was "' + value + '"' );
				}
			}
		}
		
		protected function assertTrue( ...rest ):void {
			for each ( var value:* in rest ) {
				if ( !Boolean( value ) ) {
					fail( "Expected TRUE but was FALSE" );
				}
			}
		}
	}
}