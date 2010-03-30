package rx.impl
{
	import rx.IObserver;
	import rx.Notification;
	import rx.NotificationKind;
	
	public class OnError/*.<T>*/ extends Notification/*.<T>*/
	{
		private var _error : Error;
		
		public function OnError(error : Error)
		{
			this._error = error;
		}
		
		public override function acceptFunc(onNext : Function, onCompleted : Function = null, 
			onError : Function = null) : void
		{
			if (onError != null)
			{
				onError(_error);
			}
		}
		
		public override function get hasValue() : Boolean
		{
			return false;
		}
		
		public override function get error() : Error
		{
			return _error;
		}
		
		public override function get value() : Object // T
		{
			return null;
		}
		
		public override function get kind() : int
		{
			return NotificationKind.ON_ERROR;
		}
	}
}