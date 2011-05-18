package raix.reactive.tests.operators.errors
{
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class ErrorsSuite
	{
		public var catchErrorDefer : CatchErrorDeferedFixture;
		public var catchError : CatchErrorFixture;
		public var catchErrors : CatchErrorsFixture;
		public var onErrorResumeNext : OnErrorResumeNextFixture;
		public var timeout : TimeoutFixture;
	}
}