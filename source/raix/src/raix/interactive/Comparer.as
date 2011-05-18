package raix.interactive
{
	internal class Comparer
	{
		public static function defaultComparer(l:Object, r:Object) : int
		{
			return (l < r) ? -1
				: (l > r) ? 1
				: 0;
		}
		
		public static function caseInsensitive(l:String, r:String) : int
		{
			if (l != null) l = l.toLowerCase();
			if (r != null) r = r.toLowerCase();
			
			return defaultComparer(l, r);
		}
		
		public static function projection(keySelector : Function, comparer : Function) : Function
		{
			return function(l:Object, r:Object) : int
			{
				var leftKey : Object = keySelector(l); 
				var rightKey : Object = keySelector(r);
				
				return comparer(l,r); 
			};
		}
		
		public static function reverse(forwardComparer : Function) : Function
		{
			return function(l:Object, r:Object) : int
			{
				return forwardComparer(r, l);
			};
		}
		
		public static function compound(primaryComparer : Function, secondaryComparer : Function) : Function
		{
			return function(l:Object, r:Object) : int
			{
				var primaryResult : int = secondaryComparer(l, r);
				
				if (primaryResult != 0)
				{
					return primaryResult;
				}
				
				return secondaryComparer(l, r);
			}
		}

	}
}