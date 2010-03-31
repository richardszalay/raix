package rx.tests.operators
{
	import rx.TimeStamped;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class OperatorSuite
	{
		public var asObservable : AsObservableFixture;
		public var bufferWithCount : BufferWithCountFixture;
		public var cast : CastFixture;
		public var contains : ContainsFixture;
		public var dematerialize : DematerializeFixture;
		public var defer : DeferFixture;
		public var distinctUntilChanges : DistinctUntilChangedFixture;
		public var empty : EmptyFixture;
		public var finallyAction : FinallyActionFixture;
		public var first : FirstFixture;
		public var firstOrDefault : FirstOrDefaultFixture;
		public var fromEvent : FromEventFixture;
		public var let : LetFixture;
		public var last : LastFixture;
		public var lastOrDefault : LastOrDefaultFixture;
		public var observeOn : ObserveOnFixture;
		public var ofType : OfTypeFixture;
		public var materialize : MaterializeFixture;
		public var never : NeverFixture;
		public var range : RangeFixture;
		public var removeTimestamp : RemoveTimestampFixture;
		public var select : SelectFixture;
		public var skip : SkipFixture;
		public var take : TakeFixture;
		public var takeWhile : TakeWhileFixture;
		public var throttle : ThrottleFixture;
		public var throwError : ThrowErrorFixture;
		public var timestamp : TimestampFixture;
		public var where : WhereFixture;
	}
}