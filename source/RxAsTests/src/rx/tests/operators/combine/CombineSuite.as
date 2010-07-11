package rx.tests.operators.combine
{
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class CombineSuite
	{
		public var amb : AmbFixture;
		public var combineLatest : CombineLatestFixture;
		public var concat : ConcatFixture;
		public var forkJoin : ForkJoinFixture;
		public var forkJoinInstance : ForkJoinInstanceFixture;
		public var joinCounter : JoinCounterFixture;
		public var join : JoinFixture;
		public var merge : MergeFixture;
	}
}