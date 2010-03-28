package rx.util
{
	public class ComparerUtil
	{
		public static function normalizeComaparer(source : Function) : Function
		{
			return function(a:Object,b:Object) : Boolean
			{
				var result : Object = source(a, b);
				
				if (result is Boolean)
				{
					return (result == true);
				}
				
				if (result is int || result is Number || result is uint)
				{
					return (result == 0);
				}
				
				throw new ArgumentError("comparer function must return Boolean or int");
			};
		}
	}
}