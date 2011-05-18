package raix.reactive.tests.subjects
{
	import raix.reactive.TimeStamped;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class SubjectSuite
	{
		public var asyncSubject : AsyncSubjectFixture;
		public var connectableObservable : ConnectableObservableFixture;
		public var replaySubject : ReplaySubjectFixture;
	}
}