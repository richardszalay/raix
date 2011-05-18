package raix.interactive.tests.utils
{
	import raix.interactive.Enumerable;
	import raix.interactive.IEnumerable;
	
	public class InteractiveTestUtils
	{
		public static function throwError(error : Error) : IEnumerable
		{
			return Enumerable.create(
				function():Boolean { throw error; },
				function():Object { return null; });
		}

	}
}