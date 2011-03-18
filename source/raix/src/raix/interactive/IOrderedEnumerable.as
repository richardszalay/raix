package raix.interactive
{
	public interface IOrderedEnumerable extends IEnumerable
	{
		function thenBy(keySelector : Function, comparer : Function = null) : IOrderedEnumerable;
		function thenByDescending(keySelector : Function, comparer : Function = null) : IOrderedEnumerable;
		
		function createOrderedEnumerable(keySelector : Function, comparer : Function, descending : Boolean) : IOrderedEnumerable;
	}
}