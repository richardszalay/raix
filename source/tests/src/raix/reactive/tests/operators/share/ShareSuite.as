package raix.reactive.tests.operators.share
{
	import raix.reactive.TimeStamped;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class ShareSuite
	{
		public var prune : PruneFixture;
		public var publish : PublishFixture;
		public var refCount : RefCountFixture;
		public var replay : ReplayFixture;
	}
}