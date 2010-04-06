package rx
{
	public class TimeInterval
	{
		private var _value : Object;
		private var _interval : Number;
		
		public function TimeInterval(value : Object, interval : Number)
		{
			_value = value;
			_interval = interval;
		}
		
		public function get value() : Object
		{
			return _value;
		}
		
		public function get interval() : Number
		{
			return _interval;
		}
	}
}