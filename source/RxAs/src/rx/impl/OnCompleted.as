package rx.impl
{
	import rx.IObserver;
	import rx.Notification;
	import rx.NotificationKind;
	
	public class OnCompleted/*.<T>*/ extends Notification/*.<T>*/
	{
		public function OnCompleted()
		{
		}
		
		public override function acceptFunc(onNext : Function, onCompleted : Function = null, 
			onError : Function = null) : void
		{
			if (onCompleted != null)
			{
				onCompleted();
			}
		}
		
		public override function get hasValue() : Boolean
		{
			return false;
		}
		
		public override function get error() : Error
		{
			return null;
		}
		
		public override function get value() : Object // T
		{
			return null;
		}
		
		public override function get kind() : int
		{
			return NotificationKind.ON_COMPLETED;
		}

	}
}