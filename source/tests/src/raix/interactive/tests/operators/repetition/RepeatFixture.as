package raix.interactive.tests.operators.repetition
{
	import org.flexunit.Assert;
	
	import raix.interactive.Enumerable;
	import raix.interactive.toEnumerable;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class RepeatFixture
	{
		[Test]
		public function stops_repeating_empty_sequences() : void
		{
			var length : int = Enumerable.empty()
				.repeat()
				.toArray()
				.length;
			
			Assert.assertEquals(0, length);
		}
		
		[Test]
		public function repeats_forever_if_no_value_is_specified() : void
		{
			Assert.assertEquals(20, toEnumerable([1, 2])
				.repeat()
				.take(20)
				.toArray()
				.length);
		}
		
		[Test]
		public function repeats_sequence_specified_number_of_times() : void
		{
			AssertEx.assertArrayEquals(
				[1, 2, 1, 2, 1, 2],
				toEnumerable([1, 2]).repeat(3).toArray());
		}
	}
}