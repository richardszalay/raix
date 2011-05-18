package raix.interactive.tests.operators.mutation
{
	import raix.interactive.*;
	
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class MapFixture
	{
		[Test]
		public function maps_values_using_selector() : void
		{
			var values : IEnumerable = Enumerable.range(0, 2)
				.map(function(i:int):String { return i.toString(); });
			
			AssertEx.assertArrayStrictlyEquals(
				["0", "1"],
				values.toArray());
		}
	}
}