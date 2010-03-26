package rx
{
	public class TimeStamped
	{
		private var _value : Object;
		private var _time : Number;
		
		public function TimeStamped(value : Object, time : Number)
		{
			_value = value;
			_time = time;
		}
		
		public function get value() : Object
		{
			return _value;
		}
		
		public function get timestamp() : Number
		{
			return _time;
		}

	}
}