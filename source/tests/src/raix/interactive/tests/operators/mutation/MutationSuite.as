package raix.interactive.tests.operators.mutation
{
	import raix.reactive.TimeStamped;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class MutationSuite
	{
		public var map : MapFixture;
		public var mapMany : MapManyFixture;
		public var toDictionary : ToDictionaryFixture;
		public var toLookup : ToLookupFixture;
		public var toObservable : ToObservableFixture;
		public var orderBy : OrderByFixture;
	}
}