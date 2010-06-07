package samples.imageSearch
{
	import com.adobe.serialization.json.JSON;
	
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import rx.IObservable;
	import rx.Observable;
	
	public class JsonService
	{
		public function JsonService()
		{
		}
		
		/**
		 * Returns a cold observable of Object for the 
		 */		
		public function getObservable(urlRequest : URLRequest) : IObservable
		{
			return Observable.defer(Object, function():IObservable
			{
				try
				{
					var loader : URLLoader = new URLLoader();
					loader.load(urlRequest)
					
					return Observable.fromEvent(loader, Event.COMPLETE)
						.select(Object, function(e:Event):Object { return JSON.decode(loader.data); })
						.take(1);
				}
				catch(error : Error)
				{
					return Observable.throwError(error, XML)
				}
				
				return null; // Grr compiler
			});
		}
	}
}