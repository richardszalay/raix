package raix.interactive.tests.operators.filter
{
	import org.flexunit.Assert;
	
	import raix.interactive.Enumerable;
	import raix.interactive.toEnumerable;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class DefaultIfEmptyFixture
	{
		[Test]
		public function returns_default_value_if_source_sequence_is_empty() : void
		{
			Assert.assertEquals(5,
				Enumerable.empty().defaultIfEmpty(5).toArray());
		}
		
		[Test]
		public function returns_source_sequence_if_not_empty() : void
		{
			AssertEx.assertArrayEquals([1, 2, 3],
				toEnumerable([1, 2, 3]).defaultIfEmpty(5).toArray());
		}
	}
}