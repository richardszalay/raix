package raix.reactive.tests.operators
{
	import raix.reactive.tests.operators.calculation.CalculationSuite;
	import raix.reactive.tests.operators.combine.CombineSuite;
	import raix.reactive.tests.operators.composition.CompositionSuite;
	import raix.reactive.tests.operators.creation.CreationSuite;
	import raix.reactive.tests.operators.errors.ErrorsSuite;
	import raix.reactive.tests.operators.filter.FilterSuite;
	import raix.reactive.tests.operators.metadata.MetadataSuite;
	import raix.reactive.tests.operators.mutation.MutationSuite;
	import raix.reactive.tests.operators.repetition.RepetitionSuite;
	import raix.reactive.tests.operators.scheduling.SchedulingSuite;
	import raix.reactive.tests.operators.share.ShareSuite;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class OperatorSuite
	{
		public var calculationSuite : CalculationSuite;
		public var combineSuite : CombineSuite;
		public var compositionSuite : CompositionSuite;
		public var creationSuite : CreationSuite;
		public var errorsSuite : ErrorsSuite;
		public var filterSuite : FilterSuite;
		public var metadataSuite : MetadataSuite;
		public var mutationSuite : MutationSuite;
		public var repetitionSuite : RepetitionSuite;
		public var schedulingSuite : SchedulingSuite;
		public var shareSuite : ShareSuite;
	}
}