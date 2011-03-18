package raix.interactive.tests.operators.filter
{
	import org.flexunit.Assert;
	
	import raix.interactive.toEnumerable;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class ElementAtOrDefaultFixture
	{
		[Test]
		public function returns_element_at_index_if_available() : void
		{
			Assert.assertEquals(4,
				toEnumerable([1, 2, 3, 4, 5]).elementAtOrDefault(3));
		}
		
		[Test]
		public function returns_default_value_when_object_is_out_of_range() : void
		{
			Assert.assertEquals(6,
				toEnumerable([1, 2, 3, 4, 5]).elementAtOrDefault(5, 6));
		}
	}
}