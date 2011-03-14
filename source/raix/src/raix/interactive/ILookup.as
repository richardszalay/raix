package raix.interactive
{
	public interface ILookup extends IEnumerable
	{
		function getValues(key : Object) : IEnumerable;
		function contains(key : Object) : Boolean;
	}
}