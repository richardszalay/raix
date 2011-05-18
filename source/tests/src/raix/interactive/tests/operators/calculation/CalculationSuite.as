package raix.interactive.tests.operators.calculation
{
	import raix.reactive.TimeStamped;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class CalculationSuite
	{
		public var aggregate : ReduceFixture;
		public var scan : ScanFixture;
		public var count : CountFixture;
		public var all : AllFixture;
		public var any : AnyFixture;
		public var sequenceEqual : SequenceEqualFixture;
		public var sum : SumFixture;
		public var min : MinFixture;
		public var max : MaxFixture;
		public var average : AverageFixture;
	}
}