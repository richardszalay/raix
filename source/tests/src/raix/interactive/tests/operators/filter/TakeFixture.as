package raix.interactive.tests.operators.filter
{
	import raix.interactive.*;
	
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class TakeFixture
	{
		private var _source : IEnumerable = toEnumerable([
			"zero", "one", "two", "three", "four", "five"
		]);
		
		[Test]
		public function limits_number_of_values_taken() : void
		{
			AssertEx.assertArrayEquals(
				["zero", "one", "two"],
				_source.take(3).toArray());
		}
		
		[Test]
		public function takes_less_if_less_are_available() : void
		{
			AssertEx.assertArrayEquals(
				["zero", "one", "two"],
				_source.take(3).take(4).toArray());
		}
	}
}