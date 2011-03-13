package samples.imageSearch
{
	import flash.events.Event;
	
	import mx.controls.Image;
	
	import raix.reactive.IObservable;
	import raix.reactive.Observable;
	
	public class ImageResultLoaderService
	{
		private static const PRELOAD_TIMEOUT : int = 3000;
		
		public function ImageResultLoaderService()
		{
		}
		
		public function getObservable(source : IObservable, thumbnail : Boolean, preload : Boolean) : IObservable
		{
			return source
				.map(Image, function(result : ImageResult) : Image
				{
					return createImage(result, thumbnail);
				})
				.let(function(obs : IObservable) : IObservable
				{
					return preload
						? preloadImages(obs)
						: obs;
				});
		}
		
		private function createImage(result : ImageResult, thumbnail : Boolean) : Image
		{
			var image : Image = new Image();
					
			var url : String = thumbnail
				? result.thumbnailUrl
				: result.url;
			
			image.load(url);
			
			return image;
		}
		
		private function preloadImages(observable : IObservable) : IObservable
		{
			return observable
				.mapMany(Image, function(image:Image) : IObservable
				{
					return Observable.fromEvent(image, Event.COMPLETE)
						.map(Image, function():Image { return image; })
						.take(1)
						.timeout(PRELOAD_TIMEOUT)
						.catchError(Observable.empty(Image));
				});
		}
	}
}