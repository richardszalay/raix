package rx.tests.operators
{
	import org.flexunit.Assert;
	import org.flexunit.async.Async;
	
	import rx.IObservable;
	import rx.Observable;
	import rx.tests.mocks.ManualObservable;
	import rx.tests.mocks.StatsObserver;
	
	[TestCase]
	public class BufferWithTimeFixture
	{
		[Test(async)]
		public function values_are_buffered_in_specified_time() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.interval(50)
				.bufferWithTime(120)
				.take(3)
				.subscribe(stats);
				
			
			Async.asyncHandler(this, function():void{}, 400, null, function():void	
			{
				Assert.assertEquals(3, stats.nextCount);
			});
		}
	}
}
