package raix.reactive.tests.operators.flex
{
	import raix.reactive.TimeStamped;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class FlexSuite
	{
		public var fromCollection : FromCollectionFixture;
		public var fromViewCursor : FromViewCursorFixture;
		public var fromList : FromListFixture;
		public var responder : ResponderFixture;
	}
}