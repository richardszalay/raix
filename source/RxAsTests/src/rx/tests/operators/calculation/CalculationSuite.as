package rx.tests.operators.calculation
{
	import rx.TimeStamped;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class CalculationSuite
	{
		public var aggregate : AggregateFixture;
		public var average : AverageFixture;
		public var count : CountFixture;
		public var scan : ScanFixture;
		public var sum : SumFixture;
	}
}