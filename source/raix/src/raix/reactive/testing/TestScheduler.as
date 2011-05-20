package raix.reactive.testing
{
	import raix.reactive.BooleanCancelable;
	import raix.reactive.ICancelable;
	import raix.reactive.scheduling.IScheduler;
	
	/**
	 * 
	 */	
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
		
		public function get actionCount() : uint
		{
			return _scheduledActions.length;
		}
		
		public function schedule(action : Function, dueTime : int = 0) : ICancelable
		{
			var index : int = 0;
			
			if (dueTime <= 0)
			{
				dueTime = 1;
			}
			
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
				}
			}
			
			//trace("Scheduling action for " + dueTime + " (now " + (_now) + ") @ " + absoluteDueTime);
			
			var cancelable : BooleanCancelable = new BooleanCancelable();
			
			var newFutureAction : FutureAction = new FutureAction(function():void
			{
				if (!cancelable.isCanceled)
				{
					//trace("Calling action at " + _now);
					action();
				}
			}, absoluteDueTime);
			
			_scheduledActions.splice(index, 0, newFutureAction);
			
			return cancelable;
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
		
		/**
		 * Creates a sequence from "recorded" values that will start a new timeline for each susbcriber  
		 * @param recordedNotifications An array of Recorded instances
		 * @return An observable sequence that will start a new timeline for each susbcriber
		 */
		public function createColdObservable(recordedNotifications : Array) : ColdObservable
		{
			return new ColdObservable(this, recordedNotifications);
		}
		
		/**
		 * Creates a sequence from "recorded" values that will share a timeline between all subscribers  
		 * @param recordedNotifications An array of Recorded instances
		 * @return An observable sequence that will share a timeline between all subscribers
		 */
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