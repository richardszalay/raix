package rx.tests.operators.mutation
{
	import rx.TimeStamped;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class MutationSuite
	{
		public var bufferWithCount : BufferWithCountFixture;
		public var bufferWithTime : BufferWithTimeFixture;
		public var cast : CastFixture;
		public var delay : DelayFixture;
		public var select : MapFixture;
		public var selectMany : MapManyFixture;
		public var switchMany : SwitchManyFixture;
	}
}