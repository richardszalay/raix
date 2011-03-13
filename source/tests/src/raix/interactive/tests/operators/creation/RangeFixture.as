package raix.interactive.tests.operators.creation
{
	import raix.interactive.*;
	
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class RangeFixture
	{
		[Test]
		public function for_each_works() : void
		{
			var range : IEnumerable = Enumerable.range(0, 5);
			
			AssertEx.assertArrayEquals(
				[0, 1, 2, 3, 4],
				range.toArray());
		}
	}
}