package raix.reactive.testing
{
	import raix.reactive.Cancelable;
	import raix.reactive.ICancelable;
	import raix.reactive.scheduling.IScheduler;
	
	public class TestScheduler implements IScheduler
	{
		private var _scheduledActions : Array = new Array();
		private var _now : Number = 0;
		
		public function TestScheduler()
		{
		}
		
		public function get now() : Date
		{
			return new Date(_now);
		}
		
		public function schedule(action : Function, dueTime : int = 0) : ICancelable
		{
			var index : int = 0;
			
			var absoluteDueTime : Number = _now + dueTime;
			
			for each(var futureAction : FutureAction in _scheduledActions)
			{
				if (futureAction.dueTime > absoluteDueTime)
				{
					break;
				}
				else
				{
					index++;
					
					if (futureAction.dueTime == absoluteDueTime)
					{
						absoluteDueTime++;
					}
				}
			}
			
			var newFutureAction : FutureAction = new FutureAction(action, absoluteDueTime);
			
			_scheduledActions.splice(index, 0, newFutureAction);
			
			return Cancelable.create(function():void
			{
				var index : int = _scheduledActions.indexOf(newFutureAction);
				
				if (index != -1)
				{
					_scheduledActions.splice(index, 1);
				}
			});
		}
		
		public function run() : void
		{
			while(_scheduledActions.length > 0)
			{
				var futureAction : FutureAction = FutureAction(_scheduledActions.splice(0, 1)[0]);
				
				_now = futureAction.dueTime;
				futureAction.action();				
			}
		}
		
		public function runTo(time : Number) : void
		{
			while(_scheduledActions.length > 0)
			{
				var futureAction : FutureAction = FutureAction(_scheduledActions[0]);
				
				if (futureAction.dueTime > time)
				{
					break;
				}
				
				_scheduledActions.splice(0, 1);				
				_now = futureAction.dueTime;
				futureAction.action();
			}
			
			_now = time;
		}
		
		public function createColdObservable(recordedNotifications : Array) : ColdObservable
		{
			return new ColdObservable(this, recordedNotifications);
		}
		
		public function createHotObservable(recordedNotifications : Array) : HotObservable
		{
			return new HotObservable(this, recordedNotifications);
		}
	}
}

class FutureAction
{
	public var action : Function;
	public var dueTime : Number;
	
	public function FutureAction(action : Function, dueTime : Number)
	{
		this.action = action;
		this.dueTime = dueTime;
	}
}