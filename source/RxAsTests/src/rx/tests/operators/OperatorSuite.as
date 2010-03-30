package rx.tests.operators
{
	import rx.TimeStamped;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class OperatorSuite
	{
		public var bufferWithCount : BufferWithCountFixture;
		public var contains : ContainsFixture;
		public var dematerialize : DematerializeFixture;
		public var defer : DeferFixture;
		public var empty : EmptyFixture;
		public var fromEvent : FromEventFixture;
		public var materialize : MaterializeFixture;
		public var never : NeverFixture;
		public var range : RangeFixture;
		public var removeTimestamp : RemoveTimestampFixture;
		public var select : SelectFixture;
		public var take : TakeFixture;
		public var takeWhile : TakeWhileFixture;
		public var throttle : ThrottleFixture;
		public var throwError : ThrowErrorFixture;
		public var timestamp : TimestampFixture;
		public var where : WhereFixture;
	}
}