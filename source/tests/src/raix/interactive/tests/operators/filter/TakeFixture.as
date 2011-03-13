package raix.interactive.tests.operators.filter
{
	import raix.interactive.*;
	
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class TakeFixture
	{
		[Test]
		public function limits_number_of_values_taken() : void
		{
			var range : IEnumerable = Enumerable.range(0, 5).take(2);
			
			AssertEx.assertArrayEquals(
				[0, 1],
				range.toArray());
		}
	}
}