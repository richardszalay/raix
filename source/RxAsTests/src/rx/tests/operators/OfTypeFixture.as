package rx.tests.operators
{
	import flash.display.DisplayObject;
	import flash.events.EventDispatcher;
	import flash.text.TextField;
	
	import org.flexunit.Assert;
	
	import rx.IObservable;
	import rx.Subject;
	import rx.tests.mocks.StatsObserver;
	
	public class OfTypeFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.ofType(Object);
		}
		
		[Test]
		public function excludes_incompatible_types() : void
		{
			var manObs : Subject = new Subject(EventDispatcher);
			
			var obs : IObservable = manObs.ofType(DisplayObject);
			
			var stats : StatsObserver = new StatsObserver();
			
			obs.subscribeWith(stats);
			
			var tfA : TextField = new TextField();
			var tfB : TextField = new TextField();
			
			manObs.onNext(tfA);
			manObs.onNext(new EventDispatcher());
			manObs.onNext(tfB);
			manObs.onNext(new EventDispatcher());
			
			Assert.assertEquals(2, stats.nextCount);
			Assert.assertStrictlyEquals(tfA, stats.nextValues[0]);
			Assert.assertStrictlyEquals(tfB, stats.nextValues[1]);
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