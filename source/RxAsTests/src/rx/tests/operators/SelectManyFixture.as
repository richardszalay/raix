package rx.tests.operators
{
	import flash.errors.IllegalOperationError;
	
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.ICancelable;
	import rx.Observable;
	import rx.Subject;
	import rx.tests.mocks.StatsObserver;
	
	public class SelectManyFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.selectMany(source.type, function(pl:Object):IObservable
			{
				return Observable.returnValue(source.type, pl);
			});
		}
		
		[Test]
		public function observables_are_used_from_each_source_value() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			Observable.range(0, 3)
                .selectMany(int, function(x:int):IObservable { return Observable.range(x * 2, 2); })
                .subscribeWith(stats);
                
            Assert.assertEquals(6, stats.nextCount);
            Assert.assertEquals(0, stats.nextValues[0]);
            Assert.assertEquals(1, stats.nextValues[1]);
            Assert.assertEquals(2, stats.nextValues[2]);
            Assert.assertEquals(3, stats.nextValues[3]);
            Assert.assertEquals(4, stats.nextValues[4]);
            Assert.assertEquals(5, stats.nextValues[5]);
		}
		
		[Test]
		public function values_are_taken_from_each_selected_value() : void 
		{
			var stats : StatsObserver = new StatsObserver();

            var source : Subject = new Subject(int);
            var first : Subject = new Subject(int);
            var second : Subject = new Subject(int);

            var remaining : Array = new Array();
            remaining.push(first);
            remaining.push(second);

            source
                .selectMany(int, function(o:Object):IObservable { return remaining.shift(); })
                .subscribeWith(stats);

            source.onNext(0);
            first.onNext(1);

            source.onNext(2);
            second.onNext(3);
            first.onNext(4);
            second.onNext(5);

            Assert.assertEquals(4, stats.nextCount);
            Assert.assertEquals(1, stats.nextValues[0]);
            Assert.assertEquals(3, stats.nextValues[1]);
            Assert.assertEquals(4, stats.nextValues[2]);
            Assert.assertEquals(5, stats.nextValues[3]);
		}
		
		[Test]
		public function unsubscribe_unsubscribes_from_all() : void 
		{
			var stats : StatsObserver = new StatsObserver();

            var source : Subject = new Subject(int);
            var first : Subject = new Subject(int);
            var second : Subject = new Subject(int);

            var remaining : Array = new Array();
            remaining.push(first);
            remaining.push(second);

            var subscription : ICancelable = source
                .selectMany(int, function(o:Object):IObservable { return remaining.shift(); })
                .subscribeWith(stats);

            source.onNext(0);
            source.onNext(1);
            
			Assert.assertTrue(source.hasSubscriptions);
			Assert.assertTrue(first.hasSubscriptions);
			Assert.assertTrue(second.hasSubscriptions);
			
			subscription.cancel();

            Assert.assertFalse(source.hasSubscriptions);
			Assert.assertFalse(first.hasSubscriptions);
			Assert.assertFalse(second.hasSubscriptions);
		}
		
		[Test]
		public function source_complete_does_not_complete_sequence() : void 
		{
			var stats : StatsObserver = new StatsObserver();

            var source : Subject = new Subject(int);
            var first : Subject = new Subject(int);
            var second : Subject = new Subject(int);

            var remaining : Array = new Array();
            remaining.push(first);
            remaining.push(second);

            var subscription : ICancelable = source
                .selectMany(int, function(o:Object):IObservable { return remaining.shift(); })
                .subscribeWith(stats);

            source.onNext(0);
            source.onNext(1);
            
			Assert.assertTrue(source.hasSubscriptions);
			Assert.assertTrue(first.hasSubscriptions);
			Assert.assertTrue(second.hasSubscriptions);
			
			source.onCompleted();

			Assert.assertFalse(source.hasSubscriptions);
			Assert.assertTrue(first.hasSubscriptions);
			Assert.assertTrue(second.hasSubscriptions);
			Assert.assertFalse(stats.completedCalled);
		}
		
		[Test]
		public function source_error_unsubscribes_from_all() : void 
		{
			var stats : StatsObserver = new StatsObserver();

            var source : Subject = new Subject(int);
            var first : Subject = new Subject(int);
            var second : Subject = new Subject(int);

            var remaining : Array = new Array();
            remaining.push(first);
            remaining.push(second);

            var subscription : ICancelable = source
                .selectMany(int, function(o:Object):IObservable { return remaining.shift(); })
                .subscribeWith(stats);

            source.onNext(0);
            source.onNext(1);
            
			Assert.assertTrue(source.hasSubscriptions);
			Assert.assertTrue(first.hasSubscriptions);
			Assert.assertTrue(second.hasSubscriptions);
			
			source.onError(new Error());

            Assert.assertFalse(source.hasSubscriptions);
			Assert.assertFalse(first.hasSubscriptions);
			Assert.assertFalse(second.hasSubscriptions);
			Assert.assertTrue(stats.errorCalled);
		}

		[Test]
		public function inner_source_complete_only_subscribes_from_output() : void 
		{
			var stats : StatsObserver = new StatsObserver();

            var source : Subject = new Subject(int);
            var first : Subject = new Subject(int);
            var second : Subject = new Subject(int);

            var remaining : Array = new Array();
            remaining.push(first);
            remaining.push(second);

            var subscription : ICancelable = source
                .selectMany(int, function(o:Object):IObservable { return remaining.shift(); })
                .subscribeWith(stats);

            source.onNext(0);
            source.onNext(1);
            
			Assert.assertTrue(source.hasSubscriptions);
			Assert.assertTrue(first.hasSubscriptions);
			Assert.assertTrue(second.hasSubscriptions);
			
			first.onCompleted();

            Assert.assertTrue(source.hasSubscriptions);
			Assert.assertFalse(first.hasSubscriptions);
			Assert.assertTrue(second.hasSubscriptions);
		}
		
		[Test]
		public function complete_called_when_source_completes_last() : void 
		{
			var stats : StatsObserver = new StatsObserver();

            var source : Subject = new Subject(int);
            var first : Subject = new Subject(int);
            var second : Subject = new Subject(int);

            var remaining : Array = new Array();
            remaining.push(first);
            remaining.push(second);

            var subscription : ICancelable = source
                .selectMany(int, function(o:Object):IObservable { return remaining.shift(); })
                .subscribeWith(stats);

            source.onNext(0);
            source.onNext(1);
			first.onCompleted();
			second.onCompleted();
			source.onCompleted();

            Assert.assertFalse(source.hasSubscriptions);
			Assert.assertFalse(first.hasSubscriptions);
			Assert.assertFalse(second.hasSubscriptions);
			Assert.assertTrue(stats.completedCalled);
		}

		[Test]
		public function complete_called_when_inner_source_completes_last() : void 
		{
			var stats : StatsObserver = new StatsObserver();

            var source : Subject = new Subject(int);
            var first : Subject = new Subject(int);
            var second : Subject = new Subject(int);

            var remaining : Array = new Array();
            remaining.push(first);
            remaining.push(second);

            var subscription : ICancelable = source
                .selectMany(int, function(o:Object):IObservable { return remaining.shift(); })
                .subscribeWith(stats);

            source.onNext(0);
            source.onNext(1);
			second.onCompleted();
			source.onCompleted();
			first.onCompleted();

            Assert.assertFalse(source.hasSubscriptions);
			Assert.assertFalse(first.hasSubscriptions);
			Assert.assertFalse(second.hasSubscriptions);
			Assert.assertTrue(stats.completedCalled);
		}
				
		[Test]
		public function output_error_unsubscribes_from_all() : void 
		{
			var stats : StatsObserver = new StatsObserver();

            var source : Subject = new Subject(int);
            var first : Subject = new Subject(int);
            var second : Subject = new Subject(int);

            var remaining : Array = new Array();
            remaining.push(first);
            remaining.push(second);

            var subscription : ICancelable = source
                .selectMany(int, function(o:Object):IObservable { return remaining.shift(); })
                .subscribeWith(stats);

            source.onNext(0);
            source.onNext(1);
            
			Assert.assertTrue(source.hasSubscriptions);
			Assert.assertTrue(first.hasSubscriptions);
			Assert.assertTrue(second.hasSubscriptions);
			
			first.onError(new Error());

            Assert.assertFalse(source.hasSubscriptions);
			Assert.assertFalse(first.hasSubscriptions);
			Assert.assertFalse(second.hasSubscriptions);
			Assert.assertTrue(stats.errorCalled);
		}
		
		[Test(expects="flash.errors.IllegalOperationError")]
		public function exception_thrown_when_selector_returns_null() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = Observable.range(0, 1).selectMany(int, function(i:int):IObservable
			{
				return null;
			});
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);
		}
		
		[Test]
		public function onerror_called_when_selector_throws_exception() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = Observable.range(0, 1).selectMany(int, function(i:int):IObservable
			{
				throw new IllegalOperationError();
			});
			
			var stats : StatsObserver = new StatsObserver();
			obs.subscribeWith(stats);

			manObs.onNext(0);
			
			Assert.assertTrue(stats.errorCalled);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = createEmptyObservable(manObs);
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}
	}
}