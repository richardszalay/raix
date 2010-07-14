package rx
{
	/**
	 * An error thrown by Observable.timeout by default
	 */	
	public class TimeoutError extends Error
	{
		public function TimeoutError(message : String, id : int = 0)
		{
			super(message, id);
		}

	}
}