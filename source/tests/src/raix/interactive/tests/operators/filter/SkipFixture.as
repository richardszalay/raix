package raix.interactive.tests.operators.filter
{
	import raix.interactive.*;
	
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class SkipFixture
	{
		private var _source : IEnumerable = toEnumerable([
			"zero", "one", "two", "three", "four", "five"
		]);
		
		[Test]
		public function skips_number_of_values_from_start() : void
		{
			AssertEx.assertArrayEquals(
				["three", "four", "five"],
				_source.skip(3).toArray());
		}
		
		[Test]
		public function returns_empty_if_count_is_greater_than_source() : void
		{
			AssertEx.assertArrayEquals(
				[],
				_source.skip(6).toArray());
		}
	}
}