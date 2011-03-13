package raix.interactive.tests.operators.calculation
{
	import org.flexunit.Assert;
	
	import raix.interactive.Enumerable;
	
	[TestCase]
	public class AggregateFixture
	{
		[Test]
		public function aggregates_with_accumulator_and_returns_aggregate_when_no_result_selector_specified() : void
		{
			Assert.assertEquals(6,
				Enumerable.range(1, 3)
					.aggregate(0, function(seed:int,v:int) : int { return seed + v; }));
		}
		
		[Test]
		public function maps_result_through_result_selector_if_specified() : void
		{
			Assert.assertEquals("6!",
				Enumerable.range(1, 3).aggregate(0, 
					function(seed:int,v:int) : int { return seed + v; },
					function(v:int) : String { return v.toString() + "!"; }));
		}
	}
}