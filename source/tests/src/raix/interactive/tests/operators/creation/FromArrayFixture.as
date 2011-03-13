package raix.interactive.tests.operators.creation
{
	import raix.interactive.*;
	
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class FromArrayFixture
	{
		[Test]
		public function can_convert_from_array() : void
		{
			var range : IEnumerable = Enumerable.fromArray([0, 1, 2]);
			
			AssertEx.assertArrayEquals(
				[0, 1, 2],
				range.toArray());
		}
	}
}