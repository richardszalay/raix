package rx.tests.operators.filter
{
	import rx.TimeStamped;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class FilterSuite
	{
		public var all : AllFixture;
		public var any : AnyFixture;
		public var contains : ContainsFixture;
		public var distinctUntilChanges : DistinctUntilChangedFixture;
		public var first : FirstFixture;
		public var firstOrDefault : FirstOrDefaultFixture;
		public var last : LastFixture;
		public var lastOrDefault : LastOrDefaultFixture;
		public var ofType : OfClassFixture;
		public var sample : SampleFixture;
		public var single : SingleFixture;
		public var singleOrDefault : SingleOrDefaultFixture;
		public var skip : SkipFixture;
		public var skipLast : SkipLastFixture;
		public var skipUntil : SkipUntilFixture;
		public var skipWhile : SkipWhileFixture;
		public var take : TakeFixture;
		public var takeLast : TakeLastFixture;
		public var takeUntil : TakeUntilFixture;
		public var takeWhile : TakeWhileFixture;
		public var throttle : ThrottleFixture;
		public var where : WhereFixture;
	}
}