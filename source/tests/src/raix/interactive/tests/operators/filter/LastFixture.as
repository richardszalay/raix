package raix.interactive.tests.operators.filter
{
	import org.flexunit.Assert;
	
	import raix.interactive.*;
	
	[TestCase]
	public class LastFixture
	{
		[Test]
		public function returns_last_value_on_sequence_with_single_value() : void
		{
			Assert.assertEquals(5, 
				toEnumerable([5]).last());
		}
		
		[Test]
		public function returns_last_value_on_sequence_with_single_value_matching_predicate() : void
		{
			Assert.assertEquals(5, 
				toEnumerable([5]).last(trueOncePredicate()));
		}
		
		[Test]
		public function returns_last_value_on_sequence_with_multiple_values() : void
		{
			Assert.assertEquals(1, 
				toEnumerable([5, 1]).last());
		}
		
		[Test]
		public function returns_last_value_on_sequence_with_multiple_values_matching_predicate() : void
		{
			Assert.assertEquals(1, 
				toEnumerable([5, 1]).last(function(v:Object):Boolean { return true; }));
		}
		
		[Test(expects="flash.errors.IllegalOperationError")]
		public function throws_error_on_empty_sequence() : void
		{
			Enumerable.empty().last();
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