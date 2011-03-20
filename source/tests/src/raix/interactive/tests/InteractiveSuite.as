package raix.interactive.tests
{
	import raix.interactive.tests.operators.OperatorSuite;
	import raix.interactive.tests.utils.UtilsSuite;
	
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class InteractiveSuite
	{
		public var operators : OperatorSuite;
		public var utils : UtilsSuite;
	}
}