package raix.reactive.tests.operators.combine
{
	import org.flexunit.Assert;
	
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	import raix.reactive.Subject;
	import raix.reactive.tests.mocks.StatsObserver;
	import raix.reactive.tests.operators.AbsDecoratorOperatorFixture;
	
	public class AmbFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return Observable.amb([source, Observable.never()]);
		}
		
		[Test]
		public function other_sources_are_unsubscribed_when_value_is_received() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			var subjectA : Subject = new Subject();
			var subjectB : Subject = new Subject();
			var subjectC : Subject = new Subject();
			
			Observable.amb([subjectA, subjectB, subjectC])
                .subscribeWith(stats);
                
            subjectC.onNext(0);
                
            Assert.assertFalse(subjectA.hasSubscriptions);
            Assert.assertFalse(subjectB.hasSubscriptions);
            Assert.assertTrue(subjectC.hasSubscriptions);
		}
		
		[Test]
		public function all_sources_are_unsubscribed_when_complete_is_received() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			var subjectA : Subject = new Subject();
			var subjectB : Subject = new Subject();
			var subjectC : IObservable = Observable.empty();
			
			Observable.amb([subjectA, subjectB, subjectC])
                .subscribeWith(stats);
                
            Assert.assertFalse(subjectA.hasSubscriptions);
            Assert.assertFalse(subjectB.hasSubscriptions);
            Assert.assertTrue(stats.completedCalled);            
		}
		
		[Test]
		public function all_sources_are_unsubscribed_when_error_is_received() : void
		{
			var stats : StatsObserver = new StatsObserver();
			
			var subjectA : Subject = new Subject();
			var subjectB : Subject = new Subject();
			var subjectC : IObservable = Observable.throwError(new Error());
			
			Observable.amb([subjectA, subjectB, subjectC])
                .subscribeWith(stats);
                
            Assert.assertFalse(subjectA.hasSubscriptions);
            Assert.assertFalse(subjectB.hasSubscriptions);
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