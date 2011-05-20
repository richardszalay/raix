package raix.interactive
{
	import flash.utils.*;
	
	/**
	 * Provides static methods that create IEnumerable sequences
	 */
	public class Enumerable
	{
		/**
		 * Creates an enumerable sequence that uses callbacks 
		 * @param moveNext Moves to the next item in the sequence, returning false when no more items exist:
		 *     function():Boolean
		 * @param getCurrent Retrieves the current value in the sequence: function():TElement
		 * @return An IEnumerable that contains values of type TElement 
		 */		
		public static function create(moveNext : Function, getCurrent : Function) : IEnumerable
		{
			return new ClosureEnumerable(function():IEnumerator
			{
				return new ClosureEnumerator(moveNext, getCurrent);
			});
		}
		
		/**
		 * Creates an empty sequence
		 */		
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
		
		/**
		 * Creates a sequence that contains a single value 
		 * @param value The value to wrap in a sequence
		 * @return A sequence containing the specified value
		 */		
		public static function value(value : Object) : IEnumerable
		{
			return fromArray([value]);
		}
		
		/**
		 * Creates a sequence from an enumerable proxy object
		 * @param proxy A enumerable proxy
		 * @return A sequence that will enumerate through the values in the proxy
		 */		
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
		
		/**
		 * Creates an enumerable sequence from an array 
		 * @param array The array to enumerate
		 * @return An IEnumerable containing values of the same type as array
		 */		
		public static function fromArray(array : Array) : IEnumerable
		{
			var length : int = array.length;
			
			return generate(0,
				function(i:int):Boolean { return i<length; },
				function(i:int):int { return i+1; },
				function(i:int):Object { return array[i]; }
				);
		}
		
		/**
		 * Creates an enumerable sequence that contains the numbers in a 
		 * specified range 
		 * @param start The start value
		 * @param count The number of values to enumerate, including start
		 * @return An IEnumerable of int values in the specified range
		 */		
		public static function range(start:int, count:int) : IEnumerable
		{
			var end : int = start + count - 1;
			
			return generate(start,
				function(i:int):Boolean { return i<=end; },
				function(i:int):int { return i+1; },
				function(i:int):int { return i; }
				);
		}
		
		/**
		 * Creates an enumerable sequence that repeats a value 
		 * @param val The value to repeat
		 * @param count The number of times to repeat. A value of 0 will repeat indefinately
		 * @return An IEnumerable containing the repeated value
		 */		
		public static function repeat(val : Object, count:int) : IEnumerable
		{
			return value(val).repeat(count);
		}
		
		/**
		 * Creates an enumerable sequence by calling back to functions that mainpulate its state 
		 * @param initialState The initial state value
		 * @param predicate A function called once for every value (including initialState), returns true while 
		 *     the sequence has more values: function(state : TState) : Boolean
		 * @param iterate A function called once for every value (excluding initialState) and returns the new 
		 *     value for state: function(state : TState) : TState
		 * @param resultMap A function that maps the current state to a value: 
		 *     function(state : TState) : TResult 
		 * @return An IEnumerable sequence that contains values of type TResult
		 */		
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