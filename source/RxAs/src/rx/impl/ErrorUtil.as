package rx.impl
{
	import flash.errors.IOError;
	import flash.events.ErrorEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	
	public class ErrorUtil
	{
		public function ErrorUtil()
		{
		}
		
		public static function mapErrorEvent(errorEvent : ErrorEvent) : Error
		{
			var message : String = errorEvent.text;
			
			if (errorEvent is IOErrorEvent)
			{
				return new IOError(message);
			}
			else if (errorEvent is SecurityErrorEvent)
			{
				return new SecurityError(message);
			}
			else
			{
				// TODO: Resolve error ID from message?
				
				return new Error(message);
			}
		}
	}
}