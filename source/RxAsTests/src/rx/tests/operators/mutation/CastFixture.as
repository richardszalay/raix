package rx.tests.operators.mutation
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Subject;
	import rx.tests.mocks.StatsObserver;
	import rx.tests.operators.AbsDecoratorOperatorFixture;
	
	public class CastFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.cast(Object);
		}
		
		[Test]
		public function allows_compatible_types() : void
		{
			var manObs : Subject = new Subject(EventDispatcher);
			
			var obs : IObservable = manObs.ofClass(DisplayObject);
			
			var stats : StatsObserver = new StatsObserver();
			
			obs.subscribeWith(stats);
			
			var tfA : TextField = new TextField();
			var tfB : TextField = new TextField();
			
			manObs.onNext(tfA);
			manObs.onNext(tfB);

			Assert.assertEquals(2, stats.nextCount);
			Assert.assertStrictlyEquals(tfA, stats.nextValues[0]);
			Assert.assertStrictlyEquals(tfB, stats.nextValues[1]);
		}
		
		[Test]
		public function calls_onerror_for_incompatible_types() : void
		{
			var manObs : Subject = new Subject(Event);
			
			var obs : IObservable = manObs.cast(MouseEvent);
			
			var stats : StatsObserver = new StatsObserver();
			
			obs.subscribeWith(stats);
			
			manObs.onNext(new MouseEvent("test"));
			manObs.onNext(new Event("test2"));
			
			Assert.assertEquals(1, stats.nextCount);
			Assert.assertTrue(stats.errorCalled);
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = createEmptyObservable(obs);
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}

	}
}