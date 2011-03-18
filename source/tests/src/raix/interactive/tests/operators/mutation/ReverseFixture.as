package raix.interactive.tests.operators.mutation
{
	import raix.interactive.*;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class ReverseFixture
	{
		[Test]
		public function reverses_source_order() : void
		{
			var source : Array = [1, 2, 3, 4];

		    AssertEx.assertArrayEquals(
		    	[4, 3, 2, 1], 
				toEnumerable(source).reverse().toArray());
		}
	}
}