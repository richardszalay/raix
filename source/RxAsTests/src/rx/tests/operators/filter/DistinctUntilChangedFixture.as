package rx.tests.operators.filter
{
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Subject;
	import rx.tests.mocks.StatsObserver;
	import rx.tests.operators.AbsDecoratorOperatorFixture;
	
	[TestCase]
	public class DistinctUntilChangedFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.distinctUntilChanged();
		}
		
		[Test]
		public function repeated_values_are_ignored() : void
		{
			var manObs : Subject = new Subject(int);
			
			var index : int = 0;
			
			var obs : IObservable = manObs.distinctUntilChanged();
			
			var stats : StatsObserver = new StatsObserver();			
			obs.subscribeWith(stats);
			
			manObs.onNext(0);
			manObs.onNext(0);
			manObs.onNext(1);
			manObs.onNext(1);
			manObs.onNext(2);
			manObs.onNext(2);
			manObs.onNext(0);
			
			Assert.assertEquals(4, stats.nextCount);
			Assert.assertEquals(0, stats.nextValues[0]);
			Assert.assertEquals(1, stats.nextValues[1]);
			Assert.assertEquals(2, stats.nextValues[2]);
			Assert.assertEquals(0, stats.nextValues[3]);
		}
		
		[Test]
		public function value_is_skipped_if_comparer_returns_true() : void
		{
			var manObs : Subject = new Subject(int);
			
			var index : int = 0;
			
			var obs : IObservable = manObs.distinctUntilChanged(function():Boolean
			{
				return true;
			});	
			
			var stats : StatsObserver = new StatsObserver();			
			obs.subscribeWith(stats);
			
			manObs.onNext(0);
			manObs.onNext(0);
			manObs.onNext(0);
			
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertEquals(0, stats.nextValues[0]);
		}
		
		[Test]
		public function value_is_used_if_comparer_returns_false() : void
		{
			var manObs : Subject = new Subject(int);
			
			var index : int = 0;
			
			var obs : IObservable = manObs.distinctUntilChanged(function():Boolean
			{
				return false;
			});	
			
			var stats : StatsObserver = new StatsObserver();			
			obs.subscribeWith(stats);
			
			manObs.onNext(0);
			manObs.onNext(0);
			manObs.onNext(0);
			
			Assert.assertEquals(3, stats.nextCount);
			Assert.assertEquals(0, stats.nextValues[0]);
		}
		
		[Test]
		public function value_is_not_used_if_comparer_returns_zero() : void
		{
			var manObs : Subject = new Subject(int);
			
			var index : int = 0;
			
			var obs : IObservable = manObs.distinctUntilChanged(function():int
			{
				return 0;
			});	
			
			var stats : StatsObserver = new StatsObserver();			
			obs.subscribeWith(stats);
			
			manObs.onNext(0);
			manObs.onNext(0);
			manObs.onNext(0);
			
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertEquals(0, stats.nextValues[0]);
		}
		
		[Test]
		public function value_is_used_if_comparer_returns_non_zero() : void
		{
			var manObs : Subject = new Subject(int);
			
			var index : int = 0;
			
			var obs : IObservable = manObs.distinctUntilChanged(function():int
			{
				return 1;
			});
			
			var stats : StatsObserver = new StatsObserver();			
			obs.subscribeWith(stats);
			
			manObs.onNext(0);
			manObs.onNext(0);
			manObs.onNext(0);
			
			Assert.assertEquals(3, stats.nextCount);
		}
		
		[Test]
		public function value_is_duplicate_if_comparer_returns_true() : void
		{
			var manObs : Subject = new Subject(int);
			
			var index : int = 0;
			
			var skipValue : Boolean = true;
			
			var obs : IObservable = manObs.distinctUntilChanged(function():Boolean
			{
				skipValue = !skipValue;
				
				return skipValue;
			});	
			
			var stats : StatsObserver = new StatsObserver();			
			obs.subscribeWith(stats);
			
			manObs.onNext(0); // Y
			manObs.onNext(0); // N
			manObs.onNext(0); // Y
			manObs.onNext(1); // N
			manObs.onNext(2); // Y
			manObs.onNext(3); // N
			manObs.onNext(4); // Y
			
			Assert.assertEquals(4, stats.nextCount);
			Assert.assertEquals(0, stats.nextValues[0]);
			Assert.assertEquals(0, stats.nextValues[1]);
			Assert.assertEquals(2, stats.nextValues[2]);
			Assert.assertEquals(4, stats.nextValues[3]);
		}
		
		[Test]
		public function first_value_is_exempt_from_comparison() : void
		{
			var manObs : Subject = new Subject(int);
			
			var index : int = 0;
			
			var obs : IObservable = manObs.distinctUntilChanged(function():Boolean
			{
				return true;
			});	
			
			var stats : StatsObserver = new StatsObserver();			
			obs.subscribeWith(stats);
			
			manObs.onNext(0);
			
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertEquals(0, stats.nextValues[0]);
		}
		
		[Test]
		public function errors_thrown_by_comprarer_are_sent_to_onerror() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.distinctUntilChanged(function(pl:uint) : Boolean
			{
				throw new Error();
			});
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);

			manObs.onNext(0);
			
			Assert.assertFalse(stats.nextCalled);
			Assert.assertTrue(stats.errorCalled);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.map(Boolean, function(pl:uint) : Boolean
			{
				return true;
			});
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}