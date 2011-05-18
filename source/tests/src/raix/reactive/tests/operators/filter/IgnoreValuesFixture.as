package raix.reactive.tests.operators.filter
{
	import org.flexunit.Assert;
	
	import raix.reactive.Observable;
	import raix.reactive.OnCompleted;
	import raix.reactive.OnError;
	import raix.reactive.testing.MockObserver;
	import raix.reactive.testing.TestScheduler;
	
	public class IgnoreValuesFixture
	{
		public function IgnoreValuesFixture()
		{
		}
		
		[Test]
		public function only_includes_oncomplete() : void
		{
			var observer : MockObserver = new MockObserver(new TestScheduler());
			
			Observable.range(0, 20)
				.ignoreValues()
				.subscribeWith(observer);
				
			observer.assertNotifications([
				new OnCompleted()
				], Assert.fail);
		}
		
		[Test]
		public function includes_error() : void
		{
			var observer : MockObserver = new MockObserver(new TestScheduler());
			
			var error : Error = new Error();
			
			Observable.range(0, 20)
				.concat(Observable.error(error))
				.ignoreValues()
				.subscribeWith(observer);
				
			observer.assertNotifications([
				new OnError(error)
				], Assert.fail);
		}

	}
}