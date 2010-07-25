package rx.tests.operators.creation
{
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import org.flexunit.Assert;
	import org.flexunit.async.Async;
	
	import rx.Observable;
	import rx.tests.mocks.StatsObserver; 
	
	public class UncaughtErrorsFixture
	{
		public static var loaderInfo : LoaderInfo;
		
		[Test(async)]
        public function create_calls_delegate() : void
        {
			var throwTimer : Timer = new Timer(50, 1);
        	//var loaderInfo : LoaderInfo = LoaderInfo.getLoaderInfoByDefinition(RxAsTests);

        	if (!loaderInfo.hasOwnProperty('uncaughtErrorEvents'))
        	{
        		Assert.fail("Uncaught errors cannot be tested in Flash Player < 10.1");
        	}
        	
        	var stats : StatsObserver = new StatsObserver();
        	
        	// Need to jump outside the FlexUnit callstack to test a global error.
        	// asyncHandler will be our way back in, so we can do our asserts
        	var asyncHandler : Function = Async.asyncHandler(this, function(e:Event) : void
        	{
        		Assert.assertTrue(stats.nextCalled);
        		Assert.assertTrue(stats.nextValues[0] is Error);
        		Assert.assertEquals("test", stats.nextValues[0].message);
        	}, 500);
        	
        	Observable.uncaughtErrors(loaderInfo)
        		.subscribeWith(stats);
        		
        	Assert.assertTrue(loaderInfo['uncaughtErrorEvents'].hasEventListener('uncaughtError'));
        	
        	// First timer will throw an exception from outside the FlexUnit callstack
        	var throwTimer : Timer = new Timer(50, 1);
        	throwTimer.addEventListener(TimerEvent.TIMER, function(e:Event):void
        	{
				var li : LoaderInfo = LoaderInfo.getLoaderInfoByDefinition(this);
				
				Observable.uncaughtErrors(li)
					.subscribeWith(stats);
				
        		if (!loaderInfo['uncaughtErrorEvents'].hasEventListener('uncaughtError'))
        		{
        			throw new Error("Uncaught error won't be caught");
        		}
        		
        		throw new Error("test");
        	});
        	throwTimer.start();
        	
        	// Second timer will re-enter the FlexUnit callstack to assert the caught event
        	var assertTimer : Timer = new Timer(100, 1);
        	throwTimer.addEventListener(TimerEvent.TIMER, function(e:Event):void
        	{
        		asyncHandler(e);
        	});
        	throwTimer.start();
        }
	}
}