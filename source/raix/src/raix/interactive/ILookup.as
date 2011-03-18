package raix.interactive
{
	public interface ILookup extends IEnumerable
	{
		function getValues(key : Object) : IEnumerable;
		function containsKey(key : Object) : Boolean;
	}
}