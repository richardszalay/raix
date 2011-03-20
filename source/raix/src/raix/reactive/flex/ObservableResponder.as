package raix.reactive.flex
{
	import flash.events.ErrorEvent;
	
	import mx.rpc.events.FaultEvent;
	
	import raix.reactive.*;
	import raix.reactive.impl.*;
	
	/**
	 * Concrete implementation of an observable sequence that is also an mx.rpc.IResponder
	 */	
	public class ObservableResponder extends AbsObservable implements IObservableResponder
	{
		private var _valueClass : Class;
		
		private var _observers : Array = new Array();
		
		private var _isComplete : Boolean = false;
		
		public function ObservableResponder(valueClass : Class)
		{
			_valueClass = valueClass;
		}
		
		/**
		 * Implementation of mx.rpc.IResponder.result()
		 */
		public function result(data:Object):void
		{
			if (!_isComplete)
			{
				_isComplete = true;
				
				var observers : Array = _observers.slice();
				
				for each(var observer : IObserver in observers)
				{
					observer.onNext(data);
					observer.onCompleted();
				}
			}
		}
		
		/**
		 * Implementation of mx.rpc.IResponder.fault()
		 */
		public function fault(info:Object) : void
		{
			if (!_isComplete)
			{
				_isComplete = true;
			
				var error : Error = getFaultError(info);
				
				var observers : Array = _observers.slice();
			
				for each(var observer : IObserver in observers)
				{
					observer.onError(error);
				}
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
				
				return ErrorUtil.mapErrorEvent(errorEvent);
			}
			
			return new Error((info||Object("")).toString(), 0);
		}
		
		/**
		 * @inheritDoc
		 */		
		public override function subscribeWith(observer:IObserver):ICancelable
		{
			_observers.push(observer);
			
			return Cancelable.create(function():void
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