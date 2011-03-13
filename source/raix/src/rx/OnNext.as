package rx
{
	import rx.IObserver;
	import rx.Notification;
	import rx.NotificationKind;
	
	/**
	 * A Notification for an onNext call
	 */
	public class OnNext/*.<T>*/ extends Notification/*.<T>*/
	{
		private var _value : Object;
		
		public function OnNext(value : Object /* T */)
		{
			this._value = value;
		}
		
		/**
		 * Calls onNext if it's not null
		 */
		public override function accept(onNext : Function, onCompleted : Function = null, 
			onError : Function = null) : void
		{
			if (onNext != null)
			{
				onNext(_value);
			}
		}
		
		/**
		 * Always returns true 
		 */
		public override function get hasValue() : Boolean
		{
			return true;
		}
		
		/**
		 * Always returns false since no errors are associated with values 
		 */
		public override function get error() : Error
		{
			return null;
		}
		
		/**
		 * Gets the value from the message 
		 */
		public override function get value() : Object // T
		{
			return _value;
		}
		
		/**
		 * Always returns NotificationKind.ON_NEXT 
		 */
		public override function get kind() : int
		{
			return NotificationKind.ON_NEXT;
		}

	}
}