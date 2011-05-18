package raix.interactive
{
	/**
	 * An enumerable sequence that has ordering applied to it
	 */	
	public interface IOrderedEnumerable extends IEnumerable
	{
		/**
		 * Adds a secondary sort condition to the IOrderedEnumerable
		 * @param keySelector A function that retrieves the key used to order the values in the source sequence:
		 *     function(element : TElement) : TKey
		 * @param comparer (optional) A function that compares key values. The return value should follow rules of 
		 *     the compareFunction in Array.sort: function(x : TKey, y : TKey) : int
		 * @return An IOrderedObservable that can be enumerated or further ordered using methods 
		 *     available on IOrderedObservable
		 * @see raix.interactive.IOrderedObservable
		 */
		function thenBy(keySelector : Function, comparer : Function = null) : IOrderedEnumerable;
		
		/**
		 * Adds a secondary, descending, sort condition to the IOrderedEnumerable
		 * @param keySelector A function that retrieves the key used to order the values in the source sequence:
		 *     function(element : TElement) : TKey
		 * @param comparer (optional) A function that compares key values. The return value should follow rules of 
		 *     the compareFunction in Array.sort: function(x : TKey, y : TKey) : int
		 * @return An IOrderedObservable that can be enumerated or further ordered using methods 
		 *     available on IOrderedObservable
		 * @see raix.interactive.IOrderedObservable
		 */
		function thenByDescending(keySelector : Function, comparer : Function = null) : IOrderedEnumerable;
	}
}