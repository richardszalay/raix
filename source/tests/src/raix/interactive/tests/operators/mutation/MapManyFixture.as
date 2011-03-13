package raix.interactive.tests.operators.mutation
{
	import raix.interactive.*;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class MapManyFixture
	{
		[Test]
		public function calls_result_selector_for_each_combination() : void
		{
			var numbers : Array = [3, 5, 20, 15];
			
			var mapMany : IEnumerable = toEnumerable(numbers).mapMany(
				function(x:int, index:int):IEnumerable
				{
					return toEnumerable((x+index).toString().split(""));
				},
				function(l:int, r:String) : String
				{
					return l.toString() + ": " + r;
				});
			
			AssertEx.assertArrayEquals(
				["3: 3", "5: 6", "20: 2", "20: 2", "15: 1", "15: 8"],
				mapMany.toArray());
		}
		
		[Test]
		public function returns_values_of_output_if_no_result_selector_is_given() : void
		{
			var numbers : Array = [3, 5, 20, 15];
			
			var mapMany : IEnumerable = toEnumerable(numbers).mapMany(
				function(x:int, index:int):IEnumerable
				{
					return toEnumerable((x+index).toString().split(""));
				});
			
			AssertEx.assertArrayEquals(
				["3", "6", "2", "2", "1", "8"],
				mapMany.toArray());
		}
		
		[Test(expects="ArgumentError")]
		public function returns_values_of_output_if_no_collection_selector_is_given() : void
		{
			toEnumerable(5).mapMany(null);
		}
	}
}