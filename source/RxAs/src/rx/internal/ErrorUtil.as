package rx.internal
{
	import flash.events.ErrorEvent;
	
	public class ErrorUtil
	{
		public function ErrorUtil()
		{
		}
		
		public static function mapErrorEvent(errorEvent : ErrorEvent) : Error
		{
			return new Error(errorEvent.text, 0);
		}
	}
}