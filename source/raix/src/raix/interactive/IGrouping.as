package raix.interactive
{
	/**
	 * Contains a list of grouped values and a key identifying the group
	 * @see IEnumerable.groupBy
	 */
	public interface IGrouping extends IEnumerable
	{
		/**
		 * Returns the key that identifies this grouping
		 */		
		function get key() : Object;
	}
}