package raix.reactive.tests.misc
{
	import org.flexunit.Assert;
	
	[TestCase]
	public class SliceFixture
	{
		public function SliceFixture()
		{
		}
		
		[Test]
		public function slice_duplicates_the_array() : void
		{
			var source : Array = [1, 2, 3];
			
			var target : Array = source.slice();
			
			Assert.assertFalse(source === target);
			Assert.assertEquals(source.length, target.length);
		}

	}
}