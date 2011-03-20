package raix.interactive.tests.operators.calculation
{
	import org.flexunit.Assert;
	
	import raix.interactive.toEnumerable;
	
	[TestCase]
	public class MinFixture
	{
		[Test]
		public function calculates_min_of_values_when_source_is_summable() : void
		{
			var source : Array = [
				5, 4, 1, 2, 3
			];
			
			Assert.assertEquals(1,
				toEnumerable(source).min());
		}
		
		[Test]
		public function calculates_min_of_values_using_selector() : void
		{
			var source : Array = [
				{value:5}, {value:4}, {value:1}, {value:2}, {value:3}
			];
			
			Assert.assertEquals(1,
				toEnumerable(source)
					.min(function(v:Object):int { return v.value; }));
		}
		
		[Test]
		public function calculates_min_of_values_using_comparer() : void
		{
			var source : Array = [
				{value:"five"}, {value:"four"}, 
				{value:"three"}, {value:"two"}, {value:"one"}
			];
			
			Assert.assertEquals(source[2],
				toEnumerable(source).min(null, function(l:Object, r:Object):int
				{
					return compare(l.value.charAt(1), r.value.charAt(1)); 
				}));
		}
		
		private function compare(x : Object, y : Object) : int
		{
			return (x < y) ? -1
				: (x > y) ? 1
				: 0;
		}
	}
}