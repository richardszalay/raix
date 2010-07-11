package rx.tests.operators
{
	import rx.tests.operators.calculation.CalculationSuite;
	import rx.tests.operators.combine.CombineSuite;
	import rx.tests.operators.composition.CompositionSuite;
	import rx.tests.operators.creation.CreationSuite;
	import rx.tests.operators.errors.ErrorsSuite;
	import rx.tests.operators.filter.FilterSuite;
	import rx.tests.operators.metadata.MetadataSuite;
	import rx.tests.operators.mutation.MutationSuite;
	import rx.tests.operators.repetition.RepetitionSuite;
	import rx.tests.operators.scheduling.SchedulingSuite;
	import rx.tests.operators.share.ShareSuite;
	
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