package raix.reactive.tests
{
	import org.flexunit.Assert;
	
	public class AssertEx
	{
		public static function assertArrayEquals(left : Array, right : Array, message : String = "") : void
		{
			Assert.assertEquals(message, left.length, right.length);
			
			for (var i:int =0; i<left.length; i++)
			{
				Assert.assertEquals(message + "\nValues differed at "+i,
					left[i], right[i]);
			}
		}
		
		public static function assertArrayStrictlyEquals(left : Array, right : Array, message : String = "") : void
		{
			Assert.assertEquals(message, left.length, right.length);
			
			for (var i:int =0; i<left.length; i++)
			{
				Assert.assertStrictlyEquals(message + "\nValues differed at "+i,
					left[i], right[i]);
			}
		}

	}
}