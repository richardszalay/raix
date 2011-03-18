package raix.interactive.tests.operators.filter
{
	import org.flexunit.Assert;
	
	import raix.interactive.toEnumerable;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class ContainsFixture
	{
		[Test]
		public function returns_true_if_value_can_be_found_using_default_equality() : void
		{
			var source : Array = [
				{value:1}, {value:2}, {value:3}
			];
			
			Assert.assertTrue(toEnumerable(source)
				.contains(source[1]));
		}
		
		[Test]
		public function returns_false_if_value_cannot_be_found_using_default_equality() : void
		{
			var source : Array = [
				{value:1}, {value:2}, {value:3}
			];
			
			Assert.assertFalse(toEnumerable(source)
				.contains({value:1}));
		}
		
		[Test]
		public function returns_true_if_value_can_be_found_using_selector() : void
		{
			var source : Array = [
				{value:1}, {value:2}, {value:3}
			];
			
			Assert.assertTrue(toEnumerable(source)
				.contains({value:2}, function(l:Object,r:Object):Boolean
				{
					return l.value == r.value;
				}));
		}
	}
}