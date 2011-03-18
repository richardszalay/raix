package raix.interactive.tests.operators.filter
{
	import org.flexunit.Assert;
	
	import raix.interactive.toEnumerable;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class ElementAtFixture
	{
		[Test]
		public function returns_element_at_index_if_available() : void
		{
			Assert.assertEquals(4,
				toEnumerable([1, 2, 3, 4, 5]).elementAt(3));
		}
		
		[Test(expects="RangeError")]
		public function throws_range_error_when_object_is_out_of_range() : void
		{
			toEnumerable([1, 2, 3, 4, 5]).elementAt(5);
		}
	}
}