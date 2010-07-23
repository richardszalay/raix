package rx.tests.operators.creation
{
	import rx.TimeStamped;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class CreationSuite
	{
		public var asObservable : AsObservableFixture;
		public var create : CreateFixture;
		public var createWithCancelableFixture : CreateWithCancelableFixture;
		public var defer : DeferFixture;
		public var empty : EmptyFixture;
		public var fromArray : FromArrayFixture;
		public var fromEvent : FromEventFixture;
		public var fromEvents : FromEventsFixture;
		public var ifElse : IfElseFixture;
		public var interval : IntervalFixture;
		public var lookup : LookupFixture;
		public var never : NeverFixture;
		public var range : RangeFixture;
		public var throwError : ThrowErrorFixture;
		public var timer : TimerFixture;
		public var urlLoader : URLLoaderFixture;
		public var xml : XMLFixture;
	}
}