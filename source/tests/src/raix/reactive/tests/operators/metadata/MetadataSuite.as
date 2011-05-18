package raix.reactive.tests.operators.metadata
{
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class MetadataSuite
	{
		public var dematerialize : DematerializeFixture;
		public var materialize : MaterializeFixture;
		public var removeTimeInterval : RemoveTimeIntervalFixture;
		public var removeTimestamp : RemoveTimestampFixture;
		public var timeInterval : TimeIntervalFixture;
		public var timestamp : TimestampFixture;
	}
}