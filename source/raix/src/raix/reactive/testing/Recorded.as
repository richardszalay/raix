package raix.reactive.testing
{
	import raix.reactive.Notification;
	
	public class Recorded
	{
		private var _notification : Notification;
		private var _time : Number;
		
		public function Recorded(time : Number, notification : Notification)
		{
			_notification = notification;
			_time = time;
		}
		
		public function get value() : Notification
		{
			return _notification;
		}
		
		public function get time() : Number
		{
			return _time;
		}

	}
}