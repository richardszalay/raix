package raix.reactive.tests.operators.calculation
{
	import raix.reactive.TimeStamped;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class CalculationSuite
	{
		public var aggregate : ReduceFixture;
		public var average : AverageFixture;
		public var count : CountFixture;
		public var scan : ScanFixture;
		public var sum : SumFixture;
	}
}