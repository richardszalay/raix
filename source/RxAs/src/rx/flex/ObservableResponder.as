package rx.flex
{
	import flash.events.ErrorEvent;
	
	import mx.rpc.events.FaultEvent;
	
	import rx.AbsObservable;
	import rx.IObserver;
	import rx.ICancelable;
	import rx.impl.ClosureSubscription;
	
	public class ObservableResponder extends AbsObservable implements IObservableResponder
	{
		private var _type : Class;
		
		private var _observers : Array = new Array();
		
		public function ObservableResponder(type : Class)
		{
			_type = type;
		}
		
		public override function get type():Class
		{
			return _type;
		}
		
		public function result(data:Object):void
		{
			for each(var observer : IObserver in _observers)
			{
				observer.onNext(data);
				observer.onCompleted();
			}
		}
		
		public function fault(info:Object) : void
		{
			var error : Error = getFaultError(info);
			
			for each(var observer : IObserver in _observers)
			{
				observer.onError(error);
			}
		}
		
		private function getFaultError(info : Object) : Error
		{
			if (info is FaultEvent)
			{
				var faultEvent : FaultEvent = FaultEvent(info);
				
				return faultEvent.fault;
			}
			else if (info is Error)
			{
				return info as Error;
			}
			else if (info is ErrorEvent)
			{
				var errorEvent : ErrorEvent = ErrorEvent(info);
				
				return new Error(errorEvent.text, 0);
			}
			
			return new Error((info||"").toString(), 0);
		}
		
		public override function subscribe(observer:IObserver):ICancelable
		{
			_observers.push(observer);
			
			return new ClosureSubscription(function():void
			{
				var index : int = _observers.indexOf(observer);
				
				if (index != -1)
				{
					_observers.splice(index, 1);
				}
			});
		}
	}
}