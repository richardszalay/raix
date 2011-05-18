package raix.interactive.tests.operators
{
	import raix.interactive.tests.operators.calculation.CalculationSuite;
	import raix.interactive.tests.operators.combine.CombineSuite;
	import raix.interactive.tests.operators.creation.CreationSuite;
	import raix.interactive.tests.operators.filter.FilterSuite;
	import raix.interactive.tests.operators.mutation.MutationSuite;
	import raix.interactive.tests.operators.repetition.RepetitionSuite;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class OperatorSuite
	{
		public var creationSuite : CreationSuite;
		public var filterSuite : FilterSuite;
		public var mutationSuite : MutationSuite;
		public var reptitionSuite : RepetitionSuite;
		public var calculationSuite : CalculationSuite;
		public var combineSuite : CombineSuite;
	}
}