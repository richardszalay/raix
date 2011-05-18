package raix.interactive.tests.operators.calculation
{
	import flash.errors.IllegalOperationError;
	
	import org.flexunit.Assert;
	
	import raix.interactive.Enumerable;
	import raix.interactive.tests.utils.InteractiveTestUtils;
	
	[TestCase]
	public class AllFixture
	{
		[Test]
		public function stops_enumerating_after_first_negative_predicate_result() : void
		{
			var result : Boolean = Enumerable.value(1)
				.concat(InteractiveTestUtils.throwError(new IllegalOperationError()))
				.all(function(v:int) : Boolean { return false; });
				
			Assert.assertFalse(result);
		}
		
		[Test(expects="flash.errors.IllegalOperationError")]
		public function enumerates_until_completion_or_negative_value() : void
		{
			var result : Boolean = Enumerable.range(0, 5)
				.concat(InteractiveTestUtils.throwError(new IllegalOperationError()))
				.all(function(v:int) : Boolean { return true; });
		}
		
		[Test]
		public function returns_true_if_all_values_match_predicate() : void
		{
			var result : Boolean = Enumerable.range(0, 5)
				.all(function(v:int) : Boolean { return true; });
				
			Assert.assertTrue(result);
		}
		
		[Test(expects="ArgumentError")]
		public function throws_error_if_predicate_is_null() : void
		{
			Enumerable.range(0, 5).all(null);
		}
	}
}