package raix.interactive.tests.operators.creation
{
	import raix.interactive.*;
	
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class RangeFixture
	{
		[Test]
		public function enumerates_given_range() : void
		{
			var range : IEnumerable = Enumerable.range(0, 5);
			
			AssertEx.assertArrayEquals(
				[0, 1, 2, 3, 4],
				range.toArray());
		}
		
		[Test]
		public function second_argument_is_count() : void
		{
			var range : IEnumerable = Enumerable.range(10, 2);
			
			AssertEx.assertArrayEquals(
				[10, 11],
				range.toArray());
		}
	}
}