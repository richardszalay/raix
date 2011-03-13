package raix.interactive.tests.operators.calculation
{
	import raix.interactive.Enumerable;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class ScanFixture
	{
		[Test]
		public function aggregates_with_accumulator_and_emits_rolling_aggregate_when_no_result_selector_specified() : void
		{
			AssertEx.assertArrayStrictlyEquals(
				[1, 3, 6],
				Enumerable.range(1, 3)
					.scan(0, function(seed:int,v:int) : int { return seed + v; }).toArray());
		}
		
		[Test]
		public function maps_result_through_result_selector_if_specified() : void
		{
			AssertEx.assertArrayStrictlyEquals(
				["1!", "3!", "6!"],
				Enumerable.range(1, 3).scan(0, 
					function(seed:int,v:int) : int { return seed + v; },
					function(v:int):String { return v.toString() + "!"; }).toArray());
		}
	}
}