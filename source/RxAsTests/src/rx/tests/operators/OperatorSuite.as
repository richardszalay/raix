package rx.tests.operators
{
	import rx.TimeStamped;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class OperatorSuite
	{
		public var empty : EmptyFixture;
		public var never : NeverFixture;
		public var fromEvent : FromEventFixture;
		public var select : SelectFixture;
		public var where : WhereFixture;
		public var contains : ContainsFixture;
		public var take : TakeFixture;
		public var takeWhile : TakeWhileFixture;
		public var throttle : ThrottleFixture;
		public var timestamp : TimestampFixture;
	}
}