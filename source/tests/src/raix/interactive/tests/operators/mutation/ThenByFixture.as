package raix.interactive.tests.operators.mutation
{
	import raix.interactive.*;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class ThenByFixture
	{
		[Test]
		public function primary_ordering_takes_precedence() : void
		{
			var source : Array = [
				{ value : 1, primary : 10, secondary : 22 }, 
				{ value : 2, primary : 12, secondary : 21 }, 
				{ value : 3, primary : 11, secondary : 20 }, 
			];
			var query : IEnumerable = toEnumerable(source)
				.orderBy(function(v:Object) : int { return v.primary; })
				.thenBy(function(v:Object) : int { return v.secondary; })
				.map(function(v:Object) : int { return v.value; });
			
			AssertEx.assertArrayEquals(
				[1, 3, 2], query.toArray());
		}
		
		[Test]
		public function secondary_ordering_is_used_when_primaries_are_equal() : void
		{
			var source : Array = [
		        { value : 1, primary : 10, secondary : 22 }, 
		        { value : 2, primary : 12, secondary : 21 }, 
		        { value : 3, primary : 10, secondary : 20 }, 
		    ];
		    var query : IEnumerable = toEnumerable(source)
		    	.orderBy(function(v:Object) : int { return v.primary; })
				.thenBy(function(v:Object) : int { return v.secondary; })
		    	.map(function(v:Object) : int { return v.value; });
		    
		    AssertEx.assertArrayEquals(
		    	[3, 1, 2], query.toArray());
		}
		
		[Test]
		public function tertiary_keys() : void
		{
			var source : Array = [
				{ value : 1, primary : 10, secondary : 22, tertiary : 30 }, 
				{ value : 2, primary : 12, secondary : 21, tertiary : 31 }, 
				{ value : 3, primary : 10, secondary : 20, tertiary : 33 }, 
				{ value : 4, primary : 10, secondary : 20, tertiary : 32 } 
			];
			var query : IEnumerable = toEnumerable(source)
				.orderBy(function(v:Object) : int { return v.primary; })
				.thenBy(function(v:Object) : int { return v.secondary; })
				.thenBy(function(v:Object) : int { return v.tertiary; })
				.map(function(v:Object) : int { return v.value; });
			
			AssertEx.assertArrayEquals(
				[4, 3, 1, 2], query.toArray());
		}
		
		
	}
}