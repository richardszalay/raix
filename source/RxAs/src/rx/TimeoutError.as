package rx
{
	public class TimeoutError extends Error
	{
		public function TimeoutError(message : String, id : int = 0)
		{
			super(message, id);
		}

	}
}