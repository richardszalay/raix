package raix.interactive.tests.operators.filter
{
	import raix.reactive.TimeStamped;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class FilterSuite
	{
		public var filter : FilterFixture;
		public var ofType : OfTypeFixture;
		public var take : TakeFixture;
		public var takeLast : TakeLastFixture;
		public var takeWhile : TakeWhileFixture;
		public var skip : SkipFixture;
		public var skipLast : SkipLastFixture;
		public var skipWhile : SkipWhileFixture;
		public var first : FirstFixture;
		public var firstOrDefault : FirstOrDefaultFixture;
		public var single : SingleFixture;
		public var singleOrDefault : SingleOrDefaultFixture;
		public var last : LastFixture;
		public var lastOrDefault : LastOrDefaultFixture;
		public var defaultIfEmpty : DefaultIfEmptyFixture;
		public var distinct : DistinctFixture;
		public var union : UnionFixture;
		public var intersect : IntersectFixture;
		public var except : ExceptFixture;
		public var elementAt : ElementAtFixture;
		public var elementAtOrDefault : ElementAtOrDefaultFixture;
		public var contains : ContainsFixture;
	}
}