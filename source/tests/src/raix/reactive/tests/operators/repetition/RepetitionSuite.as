package raix.reactive.tests.operators.repetition
{
	import raix.reactive.TimeStamped;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class RepetitionSuite
	{
		public var repeatValue : RepeatValueFixture;
		public var repeat : RepeatFixture;
		public var retry : RetryFixture;
	}
}