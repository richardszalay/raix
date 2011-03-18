package raix.interactive.tests.operators.mutation
{
	import raix.interactive.*;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class OrderByDescendingFixture
	{
		[Test]
		public function ordering_is_stable() : void
		{
			var source : Array = [
		        { value : 1, key : 10 }, 
		        { value : 2, key : 11 }, 
		        { value : 3, key : 11 }, 
		        { value : 4, key : 10 }, 
		    ];
		    var query : IEnumerable = toEnumerable(source)
		    	.orderByDescending(function(v:Object) : int { return v.key; })
		    	.map(function(v:Object) : int { return v.value; });
			
		    AssertEx.assertArrayEquals(
		    	[2, 3, 1, 4], query.toArray());
		}
	}
}