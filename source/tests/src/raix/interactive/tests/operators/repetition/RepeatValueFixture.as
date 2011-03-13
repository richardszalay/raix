package raix.interactive.tests.operators.repetition
{
	import raix.interactive.Enumerable;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class RepeatValueFixture
	{
		[Test]
		public function repeats_value_specified_number_of_times() : void
		{
			AssertEx.assertArrayEquals(
				[5, 5, 5],
				Enumerable.repeat(5, 3).toArray());
		}
	}
}