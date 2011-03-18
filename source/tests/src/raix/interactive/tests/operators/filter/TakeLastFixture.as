package raix.interactive.tests.operators.filter
{
	import raix.interactive.*;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class TakeLastFixture
	{
		private var _source : IEnumerable = toEnumerable([
			"zero", "one", "two", "three", "four", "five"
		]);
		
		[Test]
		public function limits_number_of_values_taken() : void
		{
			AssertEx.assertArrayEquals(
				["three", "four", "five"],
				_source.takeLast(3).toArray());
		}
		
		[Test]
		public function takes_less_if_less_are_available() : void
		{
			AssertEx.assertArrayEquals(
				["three", "four", "five"],
				_source.takeLast(3).takeLast(4).toArray());
		}
	}
}