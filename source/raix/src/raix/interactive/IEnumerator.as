package raix.interactive
{
	/**
	 * Contains the state of an active enumeration.
	 */	
	public interface IEnumerator
	{
		/**
		 * Returns the current value in the sequence
		 */		
		function get current() : Object;
		
		/**
		 * Moves to the next value in the sequence 
		 * @return true if a new value is available; false if the end of the sequence has been reacheds
		 */		
		function moveNext() : Boolean;
	}
}