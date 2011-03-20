package raix.reactive.tests
{
	import raix.reactive.tests.misc.UtilitiesSuite;
	import raix.reactive.tests.operators.OperatorSuite;
	import raix.reactive.tests.operators.flex.FlexSuite;
	import raix.reactive.tests.subjects.SubjectSuite;
	import raix.reactive.tests.testing.TestingSuite;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class ReactiveSuite
	{
		public var operators : OperatorSuite;
		public var flex : FlexSuite;
		public var subject : SubjectSuite;
		public var utilities : UtilitiesSuite;
		public var testing : TestingSuite;
	}
}