package rx
{
	/**
	 * A wrapper that adds the time interval, in milliseconds,
	 * since the last values 
	 */	
	public class TimeInterval
	{
		private var _value : Object;
		private var _interval : Number;
		
		public function TimeInterval(value : Object, interval : Number)
		{
			_value = value;
			_interval = interval;
		}
		
		/**
		 * Gets the original value
		 */		
		public function get value() : Object
		{
			return _value;
		}
		
		/**
		 * Gets the internal, in milliseconds, 
		 * since the last value
		 */
		public function get interval() : Number
		{
			return _interval;
		}
	}
}