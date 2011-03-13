package raix.interactive.tests.operators.creation
{
	import org.flexunit.Assert;
	
	import raix.interactive.*;
	import raix.reactive.tests.AssertEx;
	
	[TestCase]
	public class ToEnumerableFixture
	{
		[Test]
		public function enumerates_value_if_array() : void
		{
			AssertEx.assertArrayEquals(
				[1, 2, 3, 4, 5],
				toEnumerable([1, 2, 3, 4, 5]).toArray());
		}
		
		[Test]
		public function enumerates_value_if_enumerable() : void
		{
			var source : IEnumerable = Enumerable.fromArray([1, 2]);
			
			AssertEx.assertArrayEquals(
				[1, 2],
				toEnumerable(source).toArray());
		}
		
		[Test]
		public function returns_value_if_other() : void
		{
			Assert.assertEquals(
				1,
				toEnumerable(1).toArray()[0]);
		}
	}
}