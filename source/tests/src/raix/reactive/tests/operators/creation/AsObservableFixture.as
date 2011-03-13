package raix.reactive.tests.operators.creation
{
	import org.flexunit.Assert;
	import org.flexunit.assertThat;
	import org.hamcrest.core.not;
	import org.hamcrest.object.equalTo;
	
	import raix.reactive.IObservable;
	import raix.reactive.Subject;
	import raix.reactive.tests.operators.AbsDecoratorOperatorFixture;
	
	public class AsObservableFixture extends AbsDecoratorOperatorFixture
	{
		protected override function createEmptyObservable(source:IObservable):IObservable
		{
			return source.asObservable();
		}
		
		[Test]
		public function does_not_return_original_instance() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.asObservable();
			
			assertThat(obs, not(equalTo(manObs)));
		}
		
		[Test(expects="Error")]
		public function errors_thrown_by_subscriber_are_bubbled() : void
		{
			var manObs : Subject = new Subject(int);
			
			var obs : IObservable = manObs.asObservable();
			
			obs.subscribe(
				function(pl:int):void { throw new Error(); },
				function():void { },
				function(e:Error):void { Assert.fail("Unexpected call to onError"); }
			);

			manObs.onNext(0);
		}

	}
}