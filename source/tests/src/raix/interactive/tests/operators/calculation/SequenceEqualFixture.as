package raix.interactive.tests.operators.calculation
{
	import flash.errors.IllegalOperationError;
	
	import org.flexunit.Assert;
	
	import raix.interactive.Enumerable;
	import raix.interactive.IEnumerable;
	import raix.interactive.tests.utils.InteractiveTestUtils;
	import raix.interactive.toEnumerable;
	
	[TestCase]
	public class SequenceEqualFixture
	{
		[Test]
		public function compares_each_value_using_comparer() : void
		{
			var left : Array = [
				"apples", "oranges", "pairs" 
			];
			
			var right : Array = [
				"apes", "orangutans", "pandas" 
			];
			
			Assert.assertTrue(toEnumerable(left).sequenceEqual(toEnumerable(right), 
				function(l:String,r:String):Boolean { return l.charAt(0) == r.charAt(0); })
			);
		}
		
		[Test]
		public function stops_enumerating_after_failure() : void
		{
			var left : IEnumerable = Enumerable.value(5).concat(
				InteractiveTestUtils.throwError(new IllegalOperationError()));;
			
			var right : IEnumerable = toEnumerable([1, 2, 3]);
			
			left.sequenceEqual(right, 
				function(l:int,r:int):Boolean { return false; });
		}
	}
}