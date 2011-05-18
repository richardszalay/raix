package raix.interactive.tests.operators.combine
{
	import raix.reactive.TimeStamped;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class CombineSuite
	{
		public var concat : ConcatFixture;
		public var join : JoinFixture;
		public var groupJoin : GroupJoinFixture;
		public var zip : ZipFixture;
	}
}