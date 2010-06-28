package rx.scheduling
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.core.Application;
	
	import rx.*;
	import rx.impl.TimerPool;
	import rx.impl.ClosureCancelable;
	
	public class GreenThreadScheduler implements IScheduler
	{
		private var _runningAction : Boolean = false;
		private var _pendingActions : Array = new Array();
		
		private var _contextSwitchObservable : IObservable;
		private var _contextSwitchSubscription : ICancelable;;
		
		public function GreenThreadScheduler(contextSwitchObservable : IObservable)
		{
			_contextSwitchObservable = contextSwitchObservable;
		}
		
		public function schedule(action : Function, dueTime : int = 0) : ICancelable
		{
			if (dueTime != 0)
			{
				var timer : Timer = TimerPool.instance.obtain();
				timer.delay = dueTime;
				
				var immediateScheduledAction : ICancelable = null;
				
				var handler : Function = function():void
				{
					timer.stop();
					timer.removeEventListener(TimerEvent.TIMER, handler);
					TimerPool.instance.release(timer);
					timer = null;
					
					immediateScheduledAction = schedule(action, 0);
				};
				
				timer.addEventListener(TimerEvent.TIMER, handler);
				timer.start();
				
				return new ClosureCancelable(function():void
				{
					if (timer != null)
					{
						timer.stop();
						timer.removeEventListener(TimerEvent.TIMER, handler);
						TimerPool.instance.release(timer);
					}
					else
					{
						immediateScheduledAction.cancel();
					}
				});
			}
			else
			{
				_pendingActions.push(action);
				
				if (_contextSwitchSubscription == null)
				{
					_contextSwitchSubscription = _contextSwitchObservable
						.subscribe(executeGreenThread);
				}
				
				return new ClosureCancelable(function():void
				{
					var index : int = _pendingActions.indexOf(action);
					if (index != -1)
					{
						_pendingActions.splice(index, 1);						
					}
				})
			}
		}
		
		private function executeGreenThread(... args) : void
		{
			var startTime : Number = new Date().time;
			var runTime : Number = 0;
			var maxRunTime : Number = _contextSwitchTime;
			
			_runningAction = true;
			
			try
			{
				var iterations : int = 0;
				
				while (_pendingActions.length > 0 && runTime < maxRunTime)
				{
					(_pendingActions.shift())();
					
					runTime = new Date().time - startTime;
					
					iterations++;
				}
				
				trace(iterations + " iterations on green thread");
				
				if (_pendingActions.length == 0)
				{
					stopSwitching();
				}
			}
			catch(err : Error)
			{
				_pendingActions = [];
				
				stopSwitching();
				
				throw err;
			}
			finally
			{
				_runningAction = false;
			}
		}
		
		private function stopSwitching() : void
		{
			if (_contextSwitchSubscription != null)
			{
				_contextSwitchSubscription.cancel();
				_contextSwitchSubscription = null;
			}
		}
		
		private var _contextSwitchTime : Number = 100;
		
		public function get contextSwitchTime() : Number { return _contextSwitchTime; }
		public function set contextSwitchTime(value : Number) : void { _contextSwitchTime = value; }
		
		public function get now() : Date { return new Date(); }
		
		private static var _instance : GreenThreadScheduler = new GreenThreadScheduler(
			Observable.interval(100)
			//Observable.fromEvent(Application.application.stage, Event.ENTER_FRAME)
			);
		
		public static function get instance() : GreenThreadScheduler 
		{
			return _instance;
		}
	}
}