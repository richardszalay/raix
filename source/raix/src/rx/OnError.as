package rx
{
	import rx.IObserver;
	import rx.Notification;
	import rx.NotificationKind;
	
	/**
	 * A Notification for an onError call
	 */
	public class OnError/*.<T>*/ extends Notification/*.<T>*/
	{
		private var _error : Error;
		
		public function OnError(error : Error)
		{
			this._error = error;
		}
		
		/**
		 * Calls onError if it's not null
		 */
		public override function accept(onNext : Function, onCompleted : Function = null, 
			onError : Function = null) : void
		{
			if (onError != null)
			{
				onError(_error);
			}
		}
		
		/**
		 * Always returns false since no values are associated with errors 
		 */
		public override function get hasValue() : Boolean
		{
			return false;
		}
		
		/**
		 * Gets the error for this message 
		 */
		public override function get error() : Error
		{
			return _error;
		}
		
		/**
		 * Always returns null since no values are associated with errors 
		 */
		public override function get value() : Object // T
		{
			return null;
		}
		
		/**
		 * Always returns NotificationKind.ON_ERROR 
		 */
		public override function get kind() : int
		{
			return NotificationKind.ON_ERROR;
		}
	}
}