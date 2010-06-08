package rx.tests.operators
{
	import rx.TimeStamped;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class OperatorSuite
	{
		public var aggregaet : AggregateFixture;
		public var all : AllFixture;
		public var any : AnyFixture;
		public var amb : AmbFixture;
		public var average : AverageFixture;
		public var asObservable : AsObservableFixture;
		public var bufferWithCount : BufferWithCountFixture;
		public var bufferWithTime : BufferWithTimeFixture;
		public var catchError : CatchErrorFixture;
		public var catchErrorDefered : CatchErrorDeferedFixture;
		public var cast : CastFixture;
		public var combineLatest : CombineLatestFixture;
		public var concat : ConcatFixture;
		public var contains : ContainsFixture;
		public var count : CountFixture;
		public var dematerialize : DematerializeFixture;
		public var delay : DelayFixture;
		public var delayUntil : DelayUntilFixture;
		public var defer : DeferFixture;
		public var distinctUntilChanges : DistinctUntilChangedFixture;
		public var doAction : DoActionFixture;
		public var empty : EmptyFixture;
		public var finallyAction : FinallyActionFixture;
		public var first : FirstFixture;
		public var firstOrDefault : FirstOrDefaultFixture;
		public var fromEvent : FromEventFixture;
		public var interval : IntervalFixture;
		public var join : JoinFixture;
		public var joinCounter : JoinCounterFixture;
		public var let : LetFixture;
		public var last : LastFixture;
		public var lastOrDefault : LastOrDefaultFixture;
		public var observeOn : ObserveOnFixture;
		public var onErrorResumeNext : OnErrorResumeNextFixture;
		public var ofType : OfTypeFixture;
		public var materialize : MaterializeFixture;
		public var never : NeverFixture;
		public var prune : PruneFixture;
		public var publish : PublishFixture;
		public var replay : ReplayFixture;
		public var repeat : RepeatFixture;
		public var range : RangeFixture;
		public var removeTimeInterval : RemoveTimeIntervalFixture;
		public var removeTimestamp : RemoveTimestampFixture;
		public var scan : ScanFixture;
		public var select : SelectFixture;
		public var selectMany : SelectManyFixture;
		public var single : SingleFixture;
		public var singleOrDefault : SingleOrDefaultFixture;
		public var skip : SkipFixture;
		public var skipUntil : SkipUntilFixture;
		public var skipWhile : SkipWhileFixture;
		public var sum : SumFixture;
		public var take : TakeFixture;
		public var takeUntil : TakeUntilFixture;
		public var takeWhile : TakeWhileFixture;
		public var timer : TimerFixture;
		public var timeInterval : TimeIntervalFixture;
		public var timeout : TimeoutFixture;
		public var throttle : ThrottleFixture;
		public var throwError : ThrowErrorFixture;
		public var timestamp : TimestampFixture;
		public var where : WhereFixture;
	}
}