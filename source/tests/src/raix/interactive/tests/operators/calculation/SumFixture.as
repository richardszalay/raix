package raix.interactive.tests.operators.calculation
{
	import org.flexunit.Assert;
	
	import raix.interactive.Enumerable;
	import raix.interactive.toEnumerable;
	
	[TestCase]
	public class SumFixture
	{
		[Test]
		public function calculates_sum_of_values_when_source_is_summable() : void
		{
			Assert.assertEquals(6,
				Enumerable.range(1, 3).sum());
		}
		
		[Test]
		public function calculates_sum_of_values_when_value_is_mapped() : void
		{
			var source : Array = [
				{value:1}, {value:2}, {value:3}
			];
			
			Assert.assertEquals(6,
				toEnumerable(source)
					.sum(function(v:Object):int { return v.value; }));
		}
	}
}