package raix.reactive
{
	/**
	 * A wrapper that adds a timestamp to a value
	 */	
	public class TimeStamped
	{
		private var _value : Object;
		private var _time : Number;
		
		/**
		 * Creates a TimeStamped wrapper 
		 * @param value The value from the original sequence
		 * @param time The timestamp value
		 */		
		public function TimeStamped(value : Object, time : Number)
		{
			_value = value;
			_time = time;
		}
		
		/**
		 * Gets the original value 
		 */		
		public function get value() : Object
		{
			return _value;
		}
		
		/**
		 * Gets the timestamp value 
		 */
		public function get timestamp() : Number
		{
			return _time;
		}

	}
}