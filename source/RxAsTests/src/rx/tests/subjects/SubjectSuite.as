package rx.tests.subjects
{
	import rx.TimeStamped;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class SubjectSuite
	{
		public var asyncSubject : AsyncSubjectFixture;
		public var replaySubject : ReplaySubjectFixture;
	}
}