package rx.impl
{
	import rx.IObserver;
	import rx.Notification;
	import rx.NotificationKind;
	
	public class OnNext/*.<T>*/ extends Notification/*.<T>*/
	{
		private var _value : Object;
		
		public function OnNext(value : Object /* T */)
		{
			this._value = value;
		}
		
		public override function acceptFunc(onNext : Function, onCompleted : Function = null, 
			onError : Function = null) : void
		{
			if (onNext != null)
			{
				onNext(_value);
			}
		}
		
		public override function get hasValue() : Boolean
		{
			return true;
		}
		
		public override function get error() : Error
		{
			return null;
		}
		
		public override function get value() : Object // T
		{
			return _value;
		}
		
		public override function get kind() : int
		{
			return NotificationKind.ON_NEXT;
		}

	}
}