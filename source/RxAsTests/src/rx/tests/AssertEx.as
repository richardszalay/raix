package rx.tests
{
	import org.flexunit.Assert;
	
	public class AssertEx
	{
		public static function assertArrayEquals(left : Array, right : Array, message : String = null) : void
		{
			Assert.assertEquals(message, left.length, right.length);
			
			for (var i:int =0; i<left.length; i++)
			{
				Assert.assertEquals(message + "\nValues differed at "+i,
					left.length, right.length);
			}
		}

	}
}