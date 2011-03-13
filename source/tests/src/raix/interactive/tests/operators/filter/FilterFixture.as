package raix.interactive.tests.operators.filter
{
	import raix.interactive.*;
	
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class FilterFixture
	{
		[Test]
		public function returns_values_where_predicate_returns_true() : void
		{
			var filtered : IEnumerable = Enumerable.range(0, 5)
				.filter(function(i:int):Boolean { return i > 2; });
			
			AssertEx.assertArrayEquals(
				[3, 4],
				filtered.toArray());
		}
		
		[Test]
		public function emits_nothing_if_all_values_returns_false() : void
		{
			var filtered : IEnumerable = Enumerable.range(0, 5)
				.filter(function(i:int):Boolean { return false; });
			
			AssertEx.assertArrayEquals(
				[],
				filtered.toArray());
		}
	}
}