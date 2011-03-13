package raix.interactive
{
	import flash.utils.*;
	
	public class Enumerable
	{
		public static function create(moveNext : Function, getCurrent : Function) : IEnumerable
		{
			return new ClosureEnumerable(function():IEnumerator
			{
				return new ClosureEnumerator(moveNext, getCurrent);
			});
		}
		
		public static function empty() : IEnumerable
		{
			return new ClosureEnumerable(function():IEnumerator
			{
				return new ClosureEnumerator(
					function():Boolean { return false; },
					function():Object { throw new RangeError(); }
				);
			});
		}
		
		public static function value(value : Object) : IEnumerable
		{
			return fromArray([value]);
		}
		
		public static function fromProxy(proxy : Proxy) : IEnumerable
		{
			return new ClosureEnumerable(function():IEnumerator
			{
				var currentIndex : int = 0;
				
				return new ClosureEnumerator(
					function():Boolean
					{
						currentIndex = proxy.flash_proxy::nextNameIndex(currentIndex);
						
						return currentIndex != 0;
					},
					function():Object { return proxy.flash_proxy::nextValue(currentIndex) }
				);
			});
		}
		
		public static function fromArray(array : Array) : IEnumerable
		{
			var length : int = array.length;
			
			return generate(0,
				function(i:int):Boolean { return i<length; },
				function(i:int):int { return i+1; },
				function(i:int):Object { return array[i]; }
				);
		}
		
		public static function range(start:int, count:int) : IEnumerable
		{
			var end : int = start + count - 1;
			
			return generate(start,
				function(i:int):Boolean { return i<=end; },
				function(i:int):int { return i+1; },
				function(i:int):int { return i; }
				);
		}
		
		public static function repeat(val : Object, count:int) : IEnumerable
		{
			return value(val).repeat(count);
		}
		
		public static function generate(initialState : Object,
			predicate : Function, iterate : Function, resultMap : Function) : IEnumerable
		{
			return new ClosureEnumerable(function() : IEnumerator
			{
				var currentState : Object = initialState;
				var firstIteration : Boolean = true;
				
				var currentValue : Object = null;
				
				return new ClosureEnumerator(function():Boolean
				{
					if (firstIteration)
					{
						firstIteration = !firstIteration;
					}
					else
					{
						currentState = iterate(currentState);
					}
					
					if (predicate(currentState))
					{
						currentValue = resultMap(currentState);
						
						return true;
					}
					
					return false;
				}, function():Object
				{
					return currentValue;
				});
			});
		}
	}
}