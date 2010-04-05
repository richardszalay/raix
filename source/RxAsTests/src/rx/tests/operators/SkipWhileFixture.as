package rx.tests.operators
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Observable;
	import rx.Subject;
	import rx.tests.mocks.StatsObserver;
	
	[TestCase]
	public class SkipWhileFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.skipWhile(function(pl:Object) : Boolean { return false; });
		}
		
		[Test]
		public function values_are_returned_until_predicate_returns_false() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = Observable
				.range(0, 10)
				.skipWhile(function(pl:uint) : Boolean
				{
					return pl < 5;
				});
			
			var stats : StatsObserver = new StatsObserver();
			
			obs.subscribe(stats);
			
			Assert.assertEquals(5, stats.nextCount);
			Assert.assertEquals(5, stats.nextValues[0]);
			Assert.assertEquals(6, stats.nextValues[1]);
		}
		
		[Test]
		public function errors_thrown_by_predicate_are_sent_to_onerror() : void
		{
			var obs : IObservable = Observable
				.returnValue(int, 1)
				.skipWhile(function(pl:uint) : Boolean
				{
					throw new Error();
				});
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribe(stats);
			
			Assert.assertFalse(stats.nextCalled);
			Assert.assertTrue(stats.errorCalled);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var obs : IObservable = createEmptyObservable(Observable.returnValue(int, 1));
			
			obs.subscribeFunc(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);
		}
	}
}