package raix.interactive.tests.operators.calculation
{
	import org.flexunit.Assert;
	
	import raix.interactive.Enumerable;
	
	[TestCase]
	public class CountFixture
	{
		[Test]
		public function returns_zero_for_empty_sequences() : void
		{
			Assert.assertEquals(0,
				Enumerable.empty().count());
		}
		
		[Test]
		public function returns_count_of_values_in_sequence() : void
		{
			Assert.assertEquals(5,
				Enumerable.range(0, 5).count());
		}
	}
}