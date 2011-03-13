package raix.interactive
{
	public interface IEnumerator
	{
		function get current() : Object;
		
		function moveNext() : Boolean;
	}
}