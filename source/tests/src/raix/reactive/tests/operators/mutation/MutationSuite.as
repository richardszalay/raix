package raix.reactive.tests.operators.mutation
{
	import raix.reactive.TimeStamped;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class MutationSuite
	{
		public var bufferWithCount : BufferWithCountFixture;
		public var bufferWithTime : BufferWithTimeFixture;
		public var bufferWithTimeOrCount : BufferWithTimeOrCount;
		public var cast : CastFixture;
		public var delay : DelayFixture;
		public var expand : ExpandFixture;
		public var groupBy : GroupByFixture;
		public var groupByUntil : GroupByUntilFixture;
		public var select : MapFixture;
		public var selectMany : MapManyFixture;
		public var switchMany : SwitchManyFixture;
	}
}