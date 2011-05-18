package raix.reactive.impl
{
	import flash.errors.IOError;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	
	[ExcludeClass]
	public class ErrorUtil
	{
		public function ErrorUtil()
		{
		}
		
		public static function mapErrorEvent(event : Event) : Error
		{
			var errorEvent : ErrorEvent = (event as ErrorEvent); 
			
			var message : String = (errorEvent == null)
				? event.toString()
				: errorEvent.text;
			
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