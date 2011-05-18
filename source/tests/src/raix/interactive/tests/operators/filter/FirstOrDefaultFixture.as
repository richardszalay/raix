package raix.interactive.tests.operators.filter
{
	import org.flexunit.Assert;
	
	import raix.interactive.*;
	
	[TestCase]
	public class FirstOrDefaultFixture
	{
		[Test]
		public function returns_first_value_on_sequence_with_single_value() : void
		{
			Assert.assertEquals(5, 
				toEnumerable([5]).firstOrDefault(10));
		}
		
		[Test]
		public function returns_first_value_on_sequence_with_single_value_matching_predicate() : void
		{
			Assert.assertEquals(5, 
				toEnumerable([5]).firstOrDefault(10, trueOncePredicate()));
		}
		
		[Test]
		public function returns_first_value_on_sequence_with_multiple_values() : void
		{
			Assert.assertEquals(5, 
				toEnumerable([5, 1]).firstOrDefault(10));
		}
		
		[Test]
		public function returns_first_value_on_sequence_with_multiple_values_matching_predicate() : void
		{
			Assert.assertEquals(5, 
				toEnumerable([5, 1]).firstOrDefault(10, function(v:Object):Boolean { return true; }));
		}
		
		[Test]
		public function returns_default_value_on_empty_sequence() : void
		{
			Assert.assertEquals(10, 
				Enumerable.empty().firstOrDefault(10));
		}
		
		private function trueOncePredicate() : Function
		{
			var first : Boolean = true;
			
			return function(v:Object):Boolean
			{
				if (first)
				{
					first = false;
					return true;
				}
				else
				{
					return false;
				}
			};
		}
	}
}