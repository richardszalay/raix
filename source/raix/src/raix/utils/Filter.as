package raix.utils
{
	public class Filter
	{
		public static function not(inner : Function) : Function
		{
			if (inner == null)
			{
				throw new ArgumentError("inner cannot be null");
			}
			
			return function(v : Object) : Boolean
			{
				return !inner(v); 
			};
		}
		
		public static function get notNull() : Function
		{
			return function(v : Object) : Boolean
			{
				return v != null; 
			};
		}
		
		/*
		public static function equals(value : Object, projection : Function = null, comparer : Function = null) : Function
		{
			var hasProjection : Boolean = (projection != null);
			var hasComparer : Boolean = (comparer != null);
			
			return function(v : Object) : Boolean
			{
				var projectedValue : Object = (hasProjection)
					? projection(v)
					: v;
					
				return (hasComparer)
					? comparer(projectedValue, value)
					: projectedValue == value;
			};
		}*/
	}
}