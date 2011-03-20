package raix.reactive.tests.operators.mutation
{
	import flash.errors.IllegalOperationError;
	
	import org.flexunit.Assert;
	
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	import raix.reactive.Subject;
	import raix.reactive.tests.mocks.StatsObserver;
	import raix.reactive.tests.operators.AbsDecoratorOperatorFixture;
	
	public class SwitchManyFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.switchMany(function(pl:Object):IObservable
			{
				return Observable.returnValue(pl);
			});
		}
		
		private var stats : StatsObserver = new StatsObserver();
			
		private var source : Subject = new Subject();
			
		private var childA : Subject = new Subject();
		private var childB : Subject = new Subject();
		private var childC : Subject = new Subject();
		
		[Before]
		public function setup() : void
		{
			source = new Subject();
			childA = new Subject();
			childB = new Subject();
			childC = new Subject();
		}
		
		[Test]
		public function selector_can_map_value() : void
		{
			Observable.range(0, 3)
				.switchMany(function(x:int):IObservable { return Observable.returnValue(x + 1); })
                .subscribeWith(stats);

            Assert.assertEquals(3, stats.nextCount);
            Assert.assertEquals(1, stats.nextValues[0]);
            Assert.assertEquals(2, stats.nextValues[1]);
            Assert.assertEquals(3, stats.nextValues[2]);
            Assert.assertTrue(stats.completedCalled);
		}
		
		[Test]
		public function values_are_emitted_from_the_current_child() : void
		{
			source.switchMany(function(x:IObservable):IObservable { return x; })
                .subscribeWith(stats);
                
            source.onNext(childA);
            childA.onNext(0);
            
            source.onNext(childB);
            childB.onNext(1);
            
            source.onNext(childC);
            childC.onNext(2);
            
            Assert.assertEquals(3, stats.nextCount);
            Assert.assertEquals(0, stats.nextValues[0]);
            Assert.assertEquals(1, stats.nextValues[1]);
            Assert.assertEquals(2, stats.nextValues[2]);
		}
		
		[Test]
		public function values_are_ignored_from_previous_children() : void
		{
			source.switchMany(function(x:IObservable):IObservable { return x; })
                .subscribeWith(stats);
                
            source.onNext(childA);
            source.onNext(childB);
            
            childA.onNext(0);
            
            Assert.assertFalse(stats.nextCalled);
		}
		
		[Test]
		public function children_are_subscribed_to_as_they_are_emitted() : void
		{
			source.switchMany(function(x:IObservable):IObservable { return x; })
                .subscribeWith(stats);
                
            source.onNext(childA);
            Assert.assertTrue(childA.hasSubscriptions);
            
            source.onNext(childB);
            Assert.assertTrue(childB.hasSubscriptions);
            
            source.onNext(childC);
            Assert.assertTrue(childC.hasSubscriptions);
		}
		
		[Test]
		public function previous_sequence_is_unsubscribed_from_when_its_following_subling_is_emitted() : void
		{
			source.switchMany(function(x:IObservable):IObservable { return x; })
                .subscribeWith(stats);
                
            source.onNext(childA);
            Assert.assertTrue(childA.hasSubscriptions);
            
            source.onNext(childB);
            Assert.assertFalse(childA.hasSubscriptions);
            
            source.onNext(childC);
            Assert.assertFalse(childB.hasSubscriptions);
		}
		
		[Test]
		public function completed_parent_sequence_completes_after_last_child() : void
		{
			source.switchMany(function(x:IObservable):IObservable { return x; })
                .subscribeWith(stats);
                
            source.onNext(childA);

            source.onCompleted();
            Assert.assertFalse(stats.completedCalled);
            
            childA.onCompleted();
            Assert.assertTrue(stats.completedCalled);
		}
		
		[Test]
		public function parent_sequence_completes_with_source_if_last_child_is_complete() : void
		{
			source.switchMany(function(x:IObservable):IObservable { return x; })
                .subscribeWith(stats);
                
            source.onNext(childA);
            
            childA.onCompleted();
            Assert.assertFalse(stats.completedCalled);
            
            source.onCompleted();
            Assert.assertTrue(stats.completedCalled);
		}
		
		[Test]
		public function onerror_called_when_selector_throws_exception() : void
		{
			var manObs : Subject = new Subject();
			
			var obs : IObservable = Observable.range(0, 1).switchMany(function(i:int):IObservable
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
			var manObs : Subject = new Subject();
			
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