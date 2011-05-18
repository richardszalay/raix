package raix.interactive.tests.operators.calculation
{
	import org.flexunit.Assert;
	
	import raix.interactive.Comparer;
	import raix.interactive.Enumerable;
	import raix.interactive.toEnumerable;
	
	[TestCase]
	public class AverageFixture
	{
		[Test]
		public function calculates_average_of_values_when_source_is_summable() : void
		{
			var source : Array = [
				5, 4, 1, 2, 3
			];
			
			Assert.assertEquals(3,
				toEnumerable(source).average());
		}
		
		[Test]
		public function calculates_min_of_values_using_selector() : void
		{
			var source : Array = [
				{value:5}, {value:4}, {value:1}, {value:2}, {value:3}
			];
			
			Assert.assertEquals(3,
				toEnumerable(source)
					.average(function(v:Object):int { return v.value; }));
		}
	}
}