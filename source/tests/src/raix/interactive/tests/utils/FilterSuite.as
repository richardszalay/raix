package raix.interactive.tests.utils
{
	import org.flexunit.Assert;
	
	import raix.utils.*;
	
	[TestCase]
	public class FilterSuite
	{
		[Test]
		public function notNull_returns_true_for_not_null_values() : void
		{
			Assert.assertTrue(Filter.notNull({}));
		}
		
		[Test]
		public function notNull_returns_false_for_null_values() : void
		{
			Assert.assertFalse(Filter.notNull(null));
		}
		
		[Test]
		public function not_negates_inner_function() : void
		{
			Assert.assertFalse(Filter.not(function(v:Object) : Boolean
			{
				return true;
			})(null));
		}
		
		
		[Test(expects="ArgumentError")]
		public function not_throws_error_if_inner_function_is_null() : void
		{
			Filter.not(null);
		}
	}
}
