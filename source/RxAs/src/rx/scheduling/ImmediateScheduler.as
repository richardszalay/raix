package rx.scheduling
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import rx.impl.ClosureScheduledAction;
	import rx.impl.TimerPool;
	
	public class ImmediateScheduler implements IScheduler
	{
		private var _runningAction : Boolean = false;
		private var _pendingActions : Array = new Array();
		
		public function schedule(action : Function, dueTime : int = 0) : IScheduledAction
		{
			if (dueTime != 0)
			{
				var timer : Timer = TimerPool.instance.obtain();
				//timer.repeatCount = 1;
				timer.delay = dueTime;
				
				var handler : Function = function():void
				{
					timer.stop();
					timer.removeEventListener(TimerEvent.TIMER, handler);
					TimerPool.instance.release(timer);
					timer = null;
					
					schedule(action, 0);
				};
				
				timer.addEventListener(TimerEvent.TIMER, handler);
				timer.start();
				
				return new ClosureScheduledAction(function():void
				{
					if (timer != null)
					{
						timer.stop();
						timer.removeEventListener(TimerEvent.TIMER, handler);
						TimerPool.instance.release(timer);
					}
				});
			}
			else
			{
				if (_runningAction)
				{
					_pendingActions.push(action);
				}
				else
				{
					_runningAction = true;
					
					_pendingActions.push(action);
					
					try
					{
						while (_pendingActions.length > 0)
						{
							(_pendingActions.shift())();
						}
					}
					catch(err : Error)
					{
						_pendingActions = [];
						throw err;
					}
					finally
					{
						_runningAction = false;
					}
				}
				
				return ClosureScheduledAction.empty();
			}
		}
		
		public function get now() : Date { return new Date(); }
		
		private static var _instance : ImmediateScheduler = new ImmediateScheduler();
		
		public static function get instance() : ImmediateScheduler 
		{
			return _instance;
		}
	}
}