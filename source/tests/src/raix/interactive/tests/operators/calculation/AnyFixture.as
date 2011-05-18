package raix.interactive.tests.operators.calculation
{
	import flash.errors.IllegalOperationError;
	
	import org.flexunit.Assert;
	
	import raix.interactive.Enumerable;
	import raix.interactive.tests.utils.InteractiveTestUtils;
	
	[TestCase]
	public class AnyFixture
	{
		[Test]
		public function stops_enumerating_after_first_value_if_no_predicate_given() : void
		{
			var result : Boolean = Enumerable.value(1)
				.concat(InteractiveTestUtils.throwError(new IllegalOperationError()))
				.any();
				
			Assert.assertTrue(result);
		}
		
		[Test]
		public function returns_false_if_sequence_is_empty_and_no_predicate_given() : void
		{
			var result : Boolean = Enumerable.empty()
				.any();
				
			Assert.assertFalse(result);
		}
		
		[Test]
		public function stops_enumerating_after_first_positive_predicate_result() : void
		{
			var result : Boolean = Enumerable.value(1)
				.concat(InteractiveTestUtils.throwError(new IllegalOperationError()))
				.any(function(v:int) : Boolean { return true; });
				
			Assert.assertTrue(result);
		}
		
		[Test]
		public function returns_false_if_no_values_match_predicate() : void
		{
			var result : Boolean = Enumerable.range(0, 5)
				.any(function(v:int) : Boolean { return false; });
				
			Assert.assertFalse(result);
		}
	}
}