package raix.interactive
{
	/**
	 * Contains values grouped by keys
	 * @see IEnumerable.toLookup
	 */
	public interface ILookup extends IEnumerable
	{
		/**
		 * Returns a sequence of values for the specified key or 
		 * an empty sequence if the key has no values 
		 * @param key The key to lookup
		 * @return An IEnumerable sequence of values
		 */		
		function getValues(key : Object) : IEnumerable;
		function containsKey(key : Object) : Boolean;
	}
}