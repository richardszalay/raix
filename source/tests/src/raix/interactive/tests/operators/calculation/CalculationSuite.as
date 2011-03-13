package raix.interactive.tests.operators.calculation
{
	import raix.reactive.TimeStamped;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class CalculationSuite
	{
		public var aggregate : AggregateFixture;
		public var scan : ScanFixture;
		public var count : CountFixture;
		public var all : AllFixture;
		public var any : AnyFixture;
	}
}