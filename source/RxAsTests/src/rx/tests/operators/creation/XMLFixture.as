package rx.tests.operators.creation
{
	import flash.errors.IOError;
	import flash.net.URLRequest;
	
	import org.flexunit.Assert;
	import org.flexunit.async.Async;
	
	import rx.IObservable;
	import rx.Observable;
	
	// urlLoader() is delayed because if it comes back synchronously, it causes a problem 
	// with ImmediateScheduler's trampoline
	public class XMLFixture
	{
		public function XMLFixture()
		{
		}
		
		[Test]
		public function return_sequence_has_valueClass_XML() : void
		{
			var observable : IObservable = 
				Observable.xml(new URLRequest("rx/tests/operators/creation/test.xml"));
				
			Assert.assertEquals(XML, observable.valueClass);
		}
		
		[Test(async)]
		public function loads_xml_data() : void
		{
			var result : XML = null;
			
			var nextHandler : Function = Async.asyncHandler(this, function(... args) : void
			{
				Assert.assertEquals("text node", result.inner);
			}, 5000);
			
			var completeHandler : Function = Async.asyncHandler(this, null, 5000); 

			Observable.xml(new URLRequest("rx/tests/operators/creation/test.xml"))
				.delay(50)
				.subscribe(
					function(doc:XML) : void
					{
						result = doc;
						nextHandler(null);
					},
					function():void
					{
						completeHandler(null);
					});
		}
		
		[Test(async)]
		public function passes_error_to_onerror() : void
		{
			var error : Error = null;
			
			var errorHandler : Function = Async.asyncHandler(this, function(... args) : void
			{
				Assert.assertTrue(error is IOError);
			}, 5000); 

			Observable.xml(new URLRequest("rx/tests/operators/creation/does_not_exist.xml"))
				.delay(50)
				.subscribe(null, null, function(e:Error) : void
				{
					error = e;
					errorHandler(null);
				});
		}

	}
}